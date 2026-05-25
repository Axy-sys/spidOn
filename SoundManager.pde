import javax.sound.sampled.*;

class SoundManager {
  private final int SAMPLE_RATE = 16000; // 16kHz for low resource footprint

  SoundManager() {}

  void playTone(final float frequency, final int durationMs, final float volume) {
    new Thread(new Runnable() {
      public void run() {
        try {
          // Calculate length of the buffer
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          
          // Synthesize sine wave
          for (int i = 0; i < buf.length; i++) {
            double angle = i / (SAMPLE_RATE / frequency) * 2.0 * Math.PI;
            // Linear decay/envelope at the end to prevent clicking sound
            float envelope = 1.0f;
            if (i > buf.length - 200) {
              envelope = map(buf.length - i, 0, 200, 0f, 1.0f);
            }
            buf[i] = (byte) (Math.sin(angle) * 127.0 * volume * envelope);
          }
          
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {
          // Silently fail if audio system is busy or unavailable
        }
      }
    }).start();
  }

  void playClick() {
    playTone(600, 50, 0.2f);
  }

  void playSelect() {
    playTone(850, 70, 0.15f);
  }

  void playSuccess() {
    new Thread(new Runnable() {
      public void run() {
        try {
          playToneSync(523.25f, 90, 0.25f);  // C5
          playToneSync(659.25f, 90, 0.25f);  // E5
          playToneSync(783.99f, 110, 0.25f); // G5
          playToneSync(1046.50f, 160, 0.3f); // C6
        } catch (Exception e) {}
      }
    }).start();
  }

  void playError() {
    new Thread(new Runnable() {
      public void run() {
        try {
          playToneSync(160, 140, 0.35f);
          playToneSync(110, 220, 0.35f);
        } catch (Exception e) {}
      }
    }).start();
  }

  void playInfect() {
    new Thread(new Runnable() {
      public void run() {
        try {
          playToneSync(280, 70, 0.25f);
          playToneSync(200, 70, 0.25f);
          playToneSync(130, 110, 0.25f);
        } catch (Exception e) {}
      }
    }).start();
  }

  void playHeal() {
    new Thread(new Runnable() {
      public void run() {
        try {
          playToneSync(320, 70, 0.25f);
          playToneSync(520, 70, 0.25f);
          playToneSync(720, 110, 0.25f);
        } catch (Exception e) {}
      }
    }).start();
  }

  private void playToneSync(float frequency, int durationMs, float volume) throws Exception {
    int samplesCount = durationMs * SAMPLE_RATE / 1000;
    byte[] buf = new byte[samplesCount];
    for (int i = 0; i < buf.length; i++) {
      double angle = i / (SAMPLE_RATE / frequency) * 2.0 * Math.PI;
      float envelope = 1.0f;
      if (i > buf.length - 200) {
        envelope = map(buf.length - i, 0, 200, 0f, 1.0f);
      }
      buf[i] = (byte) (Math.sin(angle) * 127.0 * volume * envelope);
    }
    AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
    SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
    sdl.open(af);
    sdl.start();
    sdl.write(buf, 0, buf.length);
    sdl.drain();
    sdl.close();
  }
}
