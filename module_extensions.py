import math
import os
import threading
import time
import wave
from array import array

try:
    import vlc
    HAS_VLC = True
except Exception:
    HAS_VLC = False

try:
    import winsound  # Windows fallback for default notes when VLC is unavailable
    HAS_WINSOUND = True
except Exception:
    HAS_WINSOUND = False


class SpecialModuleManager:
    """
    Manages special module behaviors (media deck + piano) outside main loop logic.
    """

    DEFAULT_PIANO_NOTES = {
        "piano_key_1": "C4",
        "piano_key_2": "D4",
        "piano_key_3": "E4",
        "piano_key_4": "F4",
        "piano_key_5": "G4",
        "piano_key_6": "A4",
        "piano_key_7": "B4",
        "piano_black_1": "C#4",
        "piano_black_2": "D#4",
        "piano_black_3": "F#4",
        "piano_black_4": "G#4",
        "piano_black_5": "A#4",
    }

    PIANO_KEY_ORDER = [
        "piano_key_1",
        "piano_key_2",
        "piano_key_3",
        "piano_key_4",
        "piano_key_5",
        "piano_key_6",
        "piano_key_7",
        "piano_black_1",
        "piano_black_2",
        "piano_black_3",
        "piano_black_4",
        "piano_black_5",
    ]

    NOTE_FREQUENCIES = {
        "C4": 261.63,
        "C#4": 277.18,
        "D4": 293.66,
        "D#4": 311.13,
        "E4": 329.63,
        "F4": 349.23,
        "F#4": 369.99,
        "G4": 392.00,
        "G#4": 415.30,
        "A4": 440.00,
        "A#4": 466.16,
        "B4": 493.88,
    }

    def __init__(self, app_dir, event_log=False, action_log=False):
        self.app_dir = app_dir
        self.event_log = event_log
        self.action_log = action_log
        self.lock = threading.RLock()

        self.media_cfg = {
            "left_track": "",
            "right_track": "",
            "crossfader": 0.5,
        }
        self.piano_cfg = {"keys": {}}

        self.prev_media_a = None
        self.prev_media_b = None
        self.prev_media_btn_a = 0
        self.prev_media_btn_b = 0
        self.prev_piano_key = -1
        self.prev_piano_pressed = 0

        self.vlc_available = HAS_VLC
        self.left_player = None
        self.right_player = None
        self.piano_player = None
        self.left_loaded = None
        self.right_loaded = None
        self.last_crossfader = None

        self.notes_dir = os.path.join(self.app_dir, "notes_cache")
        os.makedirs(self.notes_dir, exist_ok=True)

        if self.vlc_available:
            self._init_vlc_players()
        else:
            self._log("[INFO] python-vlc not available. Special audio playback disabled.")

    def _log(self, msg):
        print(msg)

    def _init_vlc_players(self):
        try:
            self.left_player = vlc.MediaPlayer()
            self.right_player = vlc.MediaPlayer()
            self.piano_player = vlc.MediaPlayer()
            self.left_player.audio_set_volume(50)
            self.right_player.audio_set_volume(50)
        except Exception as exc:
            self.vlc_available = False
            self.left_player = None
            self.right_player = None
            self.piano_player = None
            self._log(f"[WARNING] VLC init failed: {exc}")

    def update_config(self, config):
        with self.lock:
            special = config.get("special_modules", {}) if isinstance(config, dict) else {}
            if not isinstance(special, dict):
                special = {}

            media = special.get("media", {})
            if not isinstance(media, dict):
                media = {}
            self.media_cfg = {
                "left_track": str(media.get("left_track") or ""),
                "right_track": str(media.get("right_track") or ""),
                "crossfader": self._to_float(media.get("crossfader"), 0.5),
            }
            self.media_cfg["crossfader"] = min(1.0, max(0.0, self.media_cfg["crossfader"]))

            piano = special.get("piano", {})
            if not isinstance(piano, dict):
                piano = {}
            keys = piano.get("keys", {})
            if not isinstance(keys, dict):
                keys = {}

            normalized_keys = {}
            for key_id, default_note in self.DEFAULT_PIANO_NOTES.items():
                raw = keys.get(key_id, {})
                if not isinstance(raw, dict):
                    raw = {}
                normalized_keys[key_id] = {
                    "note": str(raw.get("note") or default_note).upper(),
                    "file_path": str(raw.get("file_path") or ""),
                }
            self.piano_cfg = {"keys": normalized_keys}

            self._apply_crossfader()

    def handle_media_payload(self, payload_parts):
        with self.lock:
            values = self._to_int_list(payload_parts)
            if not values:
                return

            # Expected (recommended) payload:
            # module_id=4 ; jogA ; jogB ; crossfader(0..100) ; btnA ; btnB
            jog_a = values[0] if len(values) > 0 else None
            jog_b = values[1] if len(values) > 1 else None
            cross = values[2] if len(values) > 2 else None
            btn_a = values[3] if len(values) > 3 else None
            btn_b = values[4] if len(values) > 4 else None

            if cross is not None:
                self.media_cfg["crossfader"] = min(1.0, max(0.0, float(cross) / 100.0))
                self._apply_crossfader()

            if jog_a is not None:
                self._handle_jog_delta("left", jog_a, self.prev_media_a)
                self.prev_media_a = jog_a

            if jog_b is not None:
                self._handle_jog_delta("right", jog_b, self.prev_media_b)
                self.prev_media_b = jog_b

            if btn_a is not None:
                if btn_a == 1 and self.prev_media_btn_a == 0:
                    self._toggle_deck("left")
                self.prev_media_btn_a = btn_a

            if btn_b is not None:
                if btn_b == 1 and self.prev_media_btn_b == 0:
                    self._toggle_deck("right")
                self.prev_media_btn_b = btn_b

    def handle_piano_payload(self, payload_parts):
        with self.lock:
            values = self._to_int_list(payload_parts)
            if not values:
                return

            # Expected (recommended) payload:
            # module_id=5 ; key_index(0..11 or -1) ; pressed(0/1)
            key_index = values[0]
            pressed = values[1] if len(values) > 1 else 1 if key_index >= 0 else 0

            should_play = False
            if pressed == 1:
                if self.prev_piano_pressed == 0 or key_index != self.prev_piano_key:
                    should_play = True

            self.prev_piano_key = key_index
            self.prev_piano_pressed = pressed

            if should_play and key_index >= 0:
                self._play_piano_index(key_index)

    def close(self):
        with self.lock:
            for player in (self.left_player, self.right_player, self.piano_player):
                if player is None:
                    continue
                try:
                    player.stop()
                except Exception:
                    pass

    def _handle_jog_delta(self, deck_name, current_val, prev_val):
        if prev_val is None:
            return
        delta = current_val - prev_val
        if delta == 0:
            return

        # Convert analog delta into small seek jog.
        step_ms = int(max(-3000, min(3000, delta * 120)))
        self._jog_deck(deck_name, step_ms)

    def _toggle_deck(self, deck_name):
        if not self.vlc_available:
            return
        player = self.left_player if deck_name == "left" else self.right_player
        if player is None:
            return

        path = self.media_cfg["left_track"] if deck_name == "left" else self.media_cfg["right_track"]
        if not path or not os.path.isfile(path):
            if self.action_log:
                self._log(f"[MEDIA] No track configured for {deck_name} deck.")
            return

        if (deck_name == "left" and self.left_loaded != path) or (deck_name == "right" and self.right_loaded != path):
            try:
                media = vlc.Media(path)
                player.set_media(media)
                if deck_name == "left":
                    self.left_loaded = path
                else:
                    self.right_loaded = path
            except Exception as exc:
                self._log(f"[WARNING] Could not load {deck_name} track: {exc}")
                return

        state = player.get_state()
        if state == vlc.State.Playing:
            player.pause()
            if self.event_log:
                self._log(f"[MEDIA] {deck_name} deck paused")
            return

        player.play()
        # Give decoder a short moment, then restore crossfader volumes.
        time.sleep(0.03)
        self._apply_crossfader()
        if self.event_log:
            self._log(f"[MEDIA] {deck_name} deck playing")

    def _jog_deck(self, deck_name, delta_ms):
        if not self.vlc_available:
            return
        player = self.left_player if deck_name == "left" else self.right_player
        if player is None:
            return
        try:
            state = player.get_state()
            if state in (vlc.State.NothingSpecial, vlc.State.Stopped, vlc.State.Error):
                return
            current = player.get_time()
            if current < 0:
                return
            target = max(0, current + int(delta_ms))
            player.set_time(target)
            if self.event_log:
                self._log(f"[MEDIA] {deck_name} jog {delta_ms}ms")
        except Exception as exc:
            self._log(f"[WARNING] Jog failed on {deck_name}: {exc}")

    def _apply_crossfader(self):
        if not self.vlc_available:
            return
        if self.left_player is None or self.right_player is None:
            return

        cross = self.media_cfg.get("crossfader", 0.5)
        left_vol = int((1.0 - cross) * 100)
        right_vol = int(cross * 100)

        if self.last_crossfader == cross:
            return

        self.left_player.audio_set_volume(left_vol)
        self.right_player.audio_set_volume(right_vol)
        self.last_crossfader = cross

    def _play_piano_index(self, key_index):
        if key_index < 0 or key_index >= len(self.PIANO_KEY_ORDER):
            return
        key_id = self.PIANO_KEY_ORDER[key_index]
        key_cfg = self.piano_cfg.get("keys", {}).get(key_id, {})
        note = str(key_cfg.get("note") or self.DEFAULT_PIANO_NOTES[key_id]).upper()
        custom_path = str(key_cfg.get("file_path") or "")

        file_to_play = ""
        if custom_path and os.path.isfile(custom_path):
            file_to_play = custom_path
        else:
            file_to_play = self._ensure_note_wav(note)

        self._play_audio_file(file_to_play, note)

    def _play_audio_file(self, file_path, note_for_fallback):
        if self.vlc_available and self.piano_player is not None:
            try:
                self.piano_player.stop()
                self.piano_player.set_media(vlc.Media(file_path))
                self.piano_player.play()
                return
            except Exception as exc:
                self._log(f"[WARNING] Piano playback via VLC failed: {exc}")

        if HAS_WINSOUND:
            freq = int(self.NOTE_FREQUENCIES.get(note_for_fallback, 440))
            duration_ms = 250
            try:
                winsound.Beep(freq, duration_ms)
            except Exception:
                pass

    def _ensure_note_wav(self, note):
        frequency = self.NOTE_FREQUENCIES.get(note, self.NOTE_FREQUENCIES["C4"])
        safe_note = note.replace("#", "s")
        target = os.path.join(self.notes_dir, f"note_{safe_note}.wav")
        if os.path.isfile(target):
            return target

        sample_rate = 44100
        duration_seconds = 0.35
        sample_count = int(sample_rate * duration_seconds)

        samples = array("h")
        amplitude = 0.35
        for i in range(sample_count):
            t = float(i) / sample_rate
            value = int(math.sin(2 * math.pi * frequency * t) * amplitude * 32767)
            samples.append(value)

        with wave.open(target, "w") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            wf.writeframes(samples.tobytes())

        return target

    @staticmethod
    def _to_float(value, default):
        try:
            return float(value)
        except Exception:
            return default

    @staticmethod
    def _to_int_list(values):
        out = []
        for value in values:
            try:
                out.append(int(value))
            except Exception:
                return []
        return out
