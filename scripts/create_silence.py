#!/usr/bin/env python3
"""
Create a silent WAV file for testing.
Godot will automatically import WAV files and can use them as audio streams.
"""

import struct
import wave
import os

def create_silent_wav(output_path, duration_seconds=30, sample_rate=44100, channels=2, bits_per_sample=16):
    """
    Create a silent WAV file.
    
    Args:
        output_path: Path to output WAV file
        duration_seconds: Duration in seconds
        sample_rate: Sample rate in Hz
        channels: Number of channels (1=mono, 2=stereo)
        bits_per_sample: Bits per sample (16 or 24)
    """
    # Calculate number of frames
    num_frames = int(duration_seconds * sample_rate)
    
    # Create silent samples (all zeros)
    # For 16-bit audio, silent is 0
    sample_width = bits_per_sample // 8
    silent_sample = b'\x00' * sample_width
    
    # Create the WAV file
    with wave.open(output_path, 'wb') as wav_file:
        wav_file.setnchannels(channels)
        wav_file.setsampwidth(sample_width)
        wav_file.setframerate(sample_rate)
        
        # Write silent frames
        for _ in range(num_frames):
            for _ in range(channels):
                wav_file.writeframes(silent_sample)
    
    print(f"Created silent WAV file: {output_path}")
    print(f"  Duration: {duration_seconds}s")
    print(f"  Sample rate: {sample_rate}Hz")
    print(f"  Channels: {channels}")
    print(f"  Bits per sample: {bits_per_sample}")
    
    # Get file size
    file_size = os.path.getsize(output_path)
    print(f"  File size: {file_size / 1024:.1f} KB")

if __name__ == "__main__":
    # Create silent audio for test chart
    output_dir = os.path.dirname(os.path.abspath(__file__))
    songs_dir = os.path.join(os.path.dirname(output_dir), "songs", "test")
    
    # Create silent audio for test chart
    output_path = os.path.join(songs_dir, "simple_test.wav")
    create_silent_wav(output_path, duration_seconds=30)
    
    print("\nDone!")