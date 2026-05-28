import javax.sound.sampled.*;
import java.util.concurrent.*;

class SoundManager {
  private final int SAMPLE_RATE = 16000; // 16kHz for low resource footprint
  private final ExecutorService executor = Executors.newFixedThreadPool(3, new ThreadFactory() {
    public Thread newThread(Runnable r) {
      Thread t = new Thread(r);
      t.setDaemon(true);
      return t;
    }
  });

  private MusicEngine musicEngine;
  private Thread musicThread;

  SoundManager() {}

  void playTone(final float frequency, final int durationMs, final float volume) {
    playToneExt(frequency, durationMs, volume, 0); // Sine
  }

  void playToneExt(final float frequency, final int durationMs, final float volume, final int waveType) {
    executor.submit(new Runnable() {
      public void run() {
        try {
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          
          for (int i = 0; i < buf.length; i++) {
            double angle = i / (SAMPLE_RATE / frequency) * 2.0 * Math.PI;
            float envelope = 1.0f;
            if (i > buf.length - 200) {
              envelope = map(buf.length - i, 0, 200, 0f, 1.0f);
            }
            
            double sample = 0;
            if (waveType == 0) { // Sine
              sample = Math.sin(angle);
            } else if (waveType == 1) { // Square
              sample = Math.sin(angle) >= 0 ? 1.0 : -1.0;
            } else if (waveType == 2) { // Sawtooth
              double phase = (i * frequency / SAMPLE_RATE) % 1.0;
              sample = 2.0 * phase - 1.0;
            } else if (waveType == 3) { // Noise
              sample = Math.random() * 2.0 - 1.0;
            }
            buf[i] = (byte) (sample * 127.0 * volume * envelope);
          }
          
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {}
      }
    });
  }

  void playClick() {
    playTone(600, 50, 0.2f);
  }

  void playSelect() {
    playTone(850, 70, 0.15f);
  }

  void playSuccess() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          playToneSync(523.25f, 90, 0.25f);  // C5
          playToneSync(659.25f, 90, 0.25f);  // E5
          playToneSync(783.99f, 110, 0.25f); // G5
          playToneSync(1046.50f, 160, 0.3f); // C6
        } catch (Exception e) {}
      }
    });
  }

  void playError() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          playToneSync(160, 140, 0.35f);
          playToneSync(110, 220, 0.35f);
        } catch (Exception e) {}
      }
    });
  }

  void playInfect() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          playToneSync(280, 70, 0.25f);
          playToneSync(200, 70, 0.25f);
          playToneSync(130, 110, 0.25f);
        } catch (Exception e) {}
      }
    });
  }

  void playHeal() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          playToneSync(320, 70, 0.25f);
          playToneSync(520, 70, 0.25f);
          playToneSync(720, 110, 0.25f);
        } catch (Exception e) {}
      }
    });
  }

  // --- NEW SFX METHODS ---

  void playGhostAttack() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          int durationMs = 500;
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          for (int i = 0; i < buf.length; i++) {
            float t = (float)i / buf.length;
            float freq = 400 - t * 320;
            double angle = i / (SAMPLE_RATE / freq) * 2.0 * Math.PI;
            double sample = (Math.sin(angle) >= 0 ? 1 : -1) * 0.5 + (Math.random() * 2.0 - 1.0) * 0.5;
            float envelope = map(buf.length - i, 0, buf.length, 0f, 1.0f);
            buf[i] = (byte) (sample * 127.0 * 0.15 * envelope);
          }
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {}
      }
    });
  }

  void playShieldLost() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          int durationMs = 300;
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          for (int i = 0; i < buf.length; i++) {
            float t = (float)i / buf.length;
            float freq = 800 - t * 600;
            double angle = i / (SAMPLE_RATE / freq) * 2.0 * Math.PI;
            float envelope = map(buf.length - i, 0, buf.length, 0f, 1.0f);
            buf[i] = (byte) (Math.sin(angle) * 127.0 * 0.25 * envelope);
          }
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {}
      }
    });
  }

  void playMissionStart() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          float[] notes = {261.63f, 329.63f, 392.00f, 523.25f}; // C4, E4, G4, C5
          for (float note : notes) {
            playToneExtSync(note, 120, 0.2f, 0); // Sine
            Thread.sleep(120);
          }
        } catch (Exception e) {}
      }
    });
  }

  void playEvidenceCollected() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          float[] notes = {523.25f, 659.25f, 783.99f, 1046.50f};
          for (int i = 0; i < 8; i++) {
            float note = notes[i % notes.length];
            playToneExt(note, 80, 0.12f, 0);
            Thread.sleep(60);
          }
        } catch (Exception e) {}
      }
    });
  }

  void playCorrectDecision() {
    playToneExt(523.25f, 80, 0.15f, 0);
  }

  void playAlarmBeat() {
    playToneExt(440.0f, 80, 0.15f, 0);
  }

  void playVictory() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          int durationMs = 2000;
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          float[] freqs = {261.63f, 329.63f, 392.00f, 493.88f, 523.25f}; // C4, E4, G4, B4, C5
          for (int i = 0; i < buf.length; i++) {
            float envelope = 1.0f;
            if (i > buf.length - 2000) {
              envelope = map(buf.length - i, 0, buf.length, 0f, 1.0f);
            }
            double val = 0;
            for (float f : freqs) {
              double angle = i / (SAMPLE_RATE / f) * 2.0 * Math.PI;
              val += Math.sin(angle);
            }
            val = (val / freqs.length) * 127.0 * 0.3 * envelope;
            buf[i] = (byte) val;
          }
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {}
      }
    });
  }

  void playDefeat() {
    executor.submit(new Runnable() {
      public void run() {
        try {
          int durationMs = 1200;
          int samplesCount = durationMs * SAMPLE_RATE / 1000;
          byte[] buf = new byte[samplesCount];
          for (int i = 0; i < buf.length; i++) {
            float t = (float)i / buf.length;
            float freq = 300 - t * 240;
            double angle = i / (SAMPLE_RATE / freq) * 2.0 * Math.PI;
            float envelope = map(buf.length - i, 0, buf.length, 0f, 1.0f);
            buf[i] = (byte) (Math.sin(angle) * 127.0 * 0.35 * envelope);
          }
          AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
          SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
          sdl.open(af);
          sdl.start();
          sdl.write(buf, 0, buf.length);
          sdl.drain();
          sdl.close();
        } catch (Exception e) {}
      }
    });
  }

  // --- MUSIC ENGINE IMPLEMENTATION ---

  void startMusic() {
    stopMusic();
    musicEngine = new MusicEngine();
    musicThread = new Thread(musicEngine);
    musicThread.setDaemon(true);
    musicThread.start();
  }

  void stopMusic() {
    if (musicEngine != null) {
      musicEngine.running = false;
    }
    if (musicThread != null) {
      musicThread.interrupt();
    }
    musicEngine = null;
    musicThread = null;
  }

  void setThreatLevel(float t) {
    if (musicEngine != null) {
      musicEngine.threatLevel = t;
    }
  }

  private class MusicEngine implements Runnable {
    private volatile boolean running = true;
    private volatile float threatLevel = 0.0f;
    private int beatCount = 0;
    
    public void run() {
      while (running) {
        try {
          float threat = threatLevel;
          int delayMs = 600;
          
          if (threat <= 40f) {
            // tension baja: 100 BPM, beat digital suave (sine wave, 110Hz bass)
            delayMs = 600;
            float freq = 110.0f;
            if (beatCount % 4 == 1) freq = 130.81f;
            else if (beatCount % 4 == 2) freq = 164.81f;
            else if (beatCount % 4 == 3) freq = 110.0f;
            
            playToneExtSync(freq, 150, 0.15f, 0); // sine
          } else if (threat <= 70f) {
            // urgencia: 120 BPM, arpegios rapidos en Re menor, staccato, square wave, arpegio 4 notas
            delayMs = 250; // 8th note at 120 BPM
            float freq = 293.66f; // D4
            int idx = beatCount % 4;
            if (idx == 1) freq = 349.23f;      // F4
            else if (idx == 2) freq = 440.00f;      // A4
            else if (idx == 3) freq = 587.33f;      // D5
            
            playToneExtSync(freq, 100, 0.04f, 1); // square
          } else {
            // alarma: 140 BPM, disonancia, notas erraticas, alarma, sawtooth sim, cluster dissonante
            delayMs = 214; // 8th note at 140 BPM
            float freq = (beatCount % 2 == 0) ? 700f : 740f;
            playToneExtSync(freq, 120, 0.03f, 2); // sawtooth
            
            if (beatCount % 2 == 0) {
              playToneExt(440.0f, 80, 0.08f, 0); // Sine wave alarm beat
            }
          }
          
          beatCount++;
          Thread.sleep(delayMs);
        } catch (InterruptedException e) {
          break;
        } catch (Exception e) {
          // ignore
        }
      }
    }
  }

  private void playToneSync(float frequency, int durationMs, float volume) throws Exception {
    playToneExtSync(frequency, durationMs, volume, 0); // Sine
  }

  private void playToneExtSync(float frequency, int durationMs, float volume, int waveType) throws Exception {
    int samplesCount = durationMs * SAMPLE_RATE / 1000;
    byte[] buf = new byte[samplesCount];
    for (int i = 0; i < buf.length; i++) {
      double angle = i / (SAMPLE_RATE / frequency) * 2.0 * Math.PI;
      float envelope = 1.0f;
      if (i > buf.length - 200) {
        envelope = map(buf.length - i, 0, 200, 0f, 1.0f);
      }
      
      double sample = 0;
      if (waveType == 0) { // Sine
        sample = Math.sin(angle);
      } else if (waveType == 1) { // Square
        sample = Math.sin(angle) >= 0 ? 1.0 : -1.0;
      } else if (waveType == 2) { // Sawtooth
        double phase = (i * frequency / SAMPLE_RATE) % 1.0;
        sample = 2.0 * phase - 1.0;
      } else if (waveType == 3) { // Noise
        sample = Math.random() * 2.0 - 1.0;
      }
      buf[i] = (byte) (sample * 127.0 * volume * envelope);
    }
    AudioFormat af = new AudioFormat(SAMPLE_RATE, 8, 1, true, false);
    SourceDataLine sdl = AudioSystem.getSourceDataLine(af);
    sdl.open(af);
    sdl.start();
    sdl.write(buf, 0, buf.length);
    sdl.drain();
    sdl.close();
  }

  private float map(float value, float start1, float stop1, float start2, float stop2) {
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
  }
}
