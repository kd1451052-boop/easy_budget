import wave
import struct
import math

def generate_tone(freq, duration, sample_rate=44100, volume=0.5):
    num_samples = int(sample_rate * duration)
    return [volume * math.sin(2 * math.pi * freq * i / sample_rate) for i in range(num_samples)]

def save_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for sample in samples:
            wav_file.writeframes(struct.pack('h', int(sample * 32767.0)))

# C major arpeggio for a "tada" sound
tone1 = generate_tone(523.25, 0.1) # C5
tone2 = generate_tone(659.25, 0.1) # E5
tone3 = generate_tone(783.99, 0.4) # G5

save_wav('assets/sounds/tada.wav', tone1 + tone2 + tone3)
print("Generated tada.wav")
