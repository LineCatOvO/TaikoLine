#!/usr/bin/env python3
"""
Create basic drum sound effects for TaikoLine.
Creates simple synthesized sounds for Don and Ka hits.
"""

import struct
import wave
import os
import math

def create_don_sound(output_path, duration=0.15, sample_rate=44100, frequency=150):
    """
    Create a Don (center hit) sound.
    A low-pitched, resonant drum sound.
    """
    num_samples = int(duration * sample_rate)
    
    # Create the sound with decay
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # Decay envelope
        envelope = math.exp(-t * 15)
        # Multiple frequencies for richer sound
        value = (
            math.sin(2 * math.pi * frequency * t) * 0.6 +
            math.sin(2 * math.pi * frequency * 2 * t) * 0.3 +
            math.sin(2 * math.pi * frequency * 0.5 * t) * 0.1
        ) * envelope
        # Convert to 16-bit integer
        sample = int(value * 32767 * 0.8)
        sample = max(-32768, min(32767, sample))
        samples.append(sample)
    
    # Write WAV file
    with wave.open(output_path, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        for sample in samples:
            wav_file.writeframes(struct.pack('<h', sample))
    
    print(f"Created Don sound: {output_path}")

def create_ka_sound(output_path, duration=0.1, sample_rate=44100, frequency=400):
    """
    Create a Ka (rim hit) sound.
    A higher-pitched, sharper sound.
    """
    num_samples = int(duration * sample_rate)
    
    # Create the sound with fast decay
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # Fast decay envelope
        envelope = math.exp(-t * 30)
        # Higher frequency with some noise-like character
        value = (
            math.sin(2 * math.pi * frequency * t) * 0.5 +
            math.sin(2 * math.pi * frequency * 1.5 * t) * 0.3 +
            math.sin(2 * math.pi * frequency * 2.5 * t) * 0.2
        ) * envelope
        # Convert to 16-bit integer
        sample = int(value * 32767 * 0.7)
        sample = max(-32768, min(32767, sample))
        samples.append(sample)
    
    # Write WAV file
    with wave.open(output_path, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        for sample in samples:
            wav_file.writeframes(struct.pack('<h', sample))
    
    print(f"Created Ka sound: {output_path}")

if __name__ == "__main__":
    # Get the sounds directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sounds_dir = os.path.join(os.path.dirname(script_dir), "resources", "sounds")
    
    # Create sounds directory if it doesn't exist
    os.makedirs(sounds_dir, exist_ok=True)
    
    # Create Don sound
    don_path = os.path.join(sounds_dir, "don.wav")
    create_don_sound(don_path)
    
    # Create Ka sound
    ka_path = os.path.join(sounds_dir, "ka.wav")
    create_ka_sound(ka_path)
    
    print("\nDone!")