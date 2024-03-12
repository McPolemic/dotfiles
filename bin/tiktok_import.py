#!/usr/bin/env python3
import argparse
import json
import subprocess
import sqlite_utils
import os

def get_config():
    config_path = os.path.expanduser('~/.config/tiktok_import/settings.json')
    default_config = {
        "video_output_directory": "~/tiktok_videos",
        "database_path": "~/tiktok.db"
    }

    if not os.path.exists(config_path):
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, 'w') as f:
            json.dump(default_config, f, indent=4)
        print(f"Config file created at {config_path}. Please update the settings and re-run the script.")
        exit()

    with open(config_path) as f:
        return json.load(f)

def run_command(command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed with error code {result.returncode}")
        print(f"Command: {command}")
        print(f"STDOUT: {result.stdout}")
        print(f"STDERR: {result.stderr}")
        exit()
    return result

def download_video_and_metadata(url, output_dir):
    video_id = run_command(['yt-dlp', url, '--get-id']).stdout.strip()
    video_path = os.path.join(output_dir, f'{video_id}.mp4')
    json_path = os.path.join(output_dir, f'{video_id}.info.json')
    if not (os.path.exists(video_path)):
        run_command(['yt-dlp', url, '--output', os.path.join(output_dir, '%(id)s.%(ext)s'), '--write-info-json'])

    return video_id

def extract_subtitles(video_id, output_dir):
    srt_path = os.path.join(output_dir, f'{video_id}.en.srt')
    if not os.path.exists(srt_path):
        run_command(['whisper', "--fp16", "False", "--language", "en", "--model", "small", "--output_dir", output_dir,  os.path.join(output_dir, f'{video_id}.mp4')])
        os.rename(os.path.join(output_dir, f'{video_id}.mp4.srt'), srt_path)
        print(f"Extracted subtitles for {video_id}")

def load_into_database(video_id, url, output_dir, db):
    json_path = os.path.join(output_dir, f'{video_id}.info.json')
    srt_path = os.path.join(output_dir, f'{video_id}.en.srt')

    if os.path.exists(json_path):
        with open(json_path) as f:
            json_data = json.load(f)
            db['videos'].insert({"video_id": video_id, "url": url, "json_data": json_data}, pk='video_id', ignore=True)
        os.remove(json_path)

    transcripts = []
    if os.path.exists(srt_path):
        with open(srt_path) as f:
            lines = f.read().splitlines()
            for i in range(0, len(lines), 4):
                timestamp = lines[i + 1]
                transcript = lines[i + 2]
                transcripts.append({'video_id': video_id, 'timestamp': timestamp, 'transcript': transcript})
        db['transcripts'].insert_all(transcripts, pk=('video_id', 'timestamp'), replace=True)
        os.remove(srt_path)

    print(f"TikTok {video_id} saved to database. Video: {os.path.join(output_dir, f'{video_id}.mp4')}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download and process TikTok videos.')
    parser.add_argument('urls', nargs='+', help='The TikTok URLs to process.')
    args = parser.parse_args()

    config = get_config()
    output_dir = os.path.expanduser(config['video_output_directory'])
    db_path = os.path.expanduser(config['database_path'])

    db = sqlite_utils.Database(db_path)

    db['videos'].create({
        "video_id": str,
        "url": str,
        "json_data": str
    }, pk='video_id', if_not_exists=True)
    db['transcripts'].create({
        "video_id": str,
        "timestamp": str,
        "transcript": str
    }, pk=('video_id', 'timestamp'), if_not_exists=True)

    for url in args.urls:
        print(f"Processing {url}...")
        video_id = download_video_and_metadata(url, output_dir)
        print(db['videos'].count_where("video_id = ?", [video_id]))
        if db['videos'].count_where("video_id = ?", [video_id]) > 0:
            print(f"Skipping {url} as it already exists in the database.")
            continue

        if db['transcripts'].count_where("video_id = ?", [video_id]) > 0:
            print(f"Skipping {url} as transcripts already exist in the database.")
        else:
            extract_subtitles(video_id, output_dir)

        load_into_database(video_id, url, output_dir, db)
