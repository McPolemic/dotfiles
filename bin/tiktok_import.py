#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sqlite_utils
import os

VIDEO_DIR = "/media/storage/Backups/August/TikTok"
DB_PATH = "/media/storage/Backups/August/TikTok/tiktok.db"

def run_command(command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed with error code {result.returncode}")
        print(f"Command: {command}")
        print(f"STDOUT: {result.stdout}")
        print(f"STDERR: {result.stderr}")
        exit()
    return result

TIKTOK_URL_PATTERN = re.compile(r'https?://(?:www\.)?tiktok(?:v)?\.com/.*?/video/(\d+)')

def extract_video_id(url):
    match = TIKTOK_URL_PATTERN.search(url)
    if match:
        return match.group(1)
    result = run_command(['yt-dlp', url, '--get-id'])
    return result.stdout.strip()

def video_id_from_content(content):
    match = TIKTOK_URL_PATTERN.search(content)
    return match.group(1) if match else None

def download_video_and_metadata(video_id, url, output_dir):
    video_path = os.path.join(output_dir, f'{video_id}.mp4')
    if not os.path.exists(video_path):
        run_command(['yt-dlp', url, '--output', os.path.join(output_dir, '%(id)s.%(ext)s'), '--write-info-json'])
    return video_path

def extract_subtitles(video_id, output_dir):
    srt_path = os.path.join(output_dir, f'{video_id}.en.srt')
    if not os.path.exists(srt_path):
        run_command(['whisper', "--fp16", "False", "--language", "en", "--model", "small", "--output_dir", output_dir,  os.path.join(output_dir, f'{video_id}.mp4')])
        os.rename(os.path.join(output_dir, f'{video_id}.mp4.srt'), srt_path)
        print(f"Extracted subtitles for {video_id}")

def load_into_database(video_id, url, video_path, output_dir, db):
    json_path = os.path.join(output_dir, f'{video_id}.info.json')
    srt_path = os.path.join(output_dir, f'{video_id}.en.srt')

    if os.path.exists(json_path):
        with open(json_path) as f:
            json_data = json.load(f)
            db['videos'].insert({"video_id": video_id, "url": url, "video_path": video_path, "json_data": json_data}, pk='video_id', ignore=True)

    transcripts = []
    if os.path.exists(srt_path):
        with open(srt_path) as f:
            lines = f.read().splitlines()
            for i in range(0, len(lines), 4):
                timestamp = lines[i + 1]
                transcript = lines[i + 2]
                transcripts.append({'video_id': video_id, 'timestamp': timestamp, 'transcript': transcript})
        db['transcripts'].insert_all(transcripts, pk=('video_id', 'timestamp'), replace=True)

    print(f"TikTok {video_id} saved to database. Video: {video_path}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download and process TikTok videos.')
    parser.add_argument('urls', nargs='*', help='The TikTok URLs to process.')
    parser.add_argument('-f', '--file', help='Path to a user_data_tiktok.json file to extract liked video URLs from.')
    parser.add_argument('-n', '--dry-run', action='store_true', help='List what would be done without downloading or modifying anything.')
    args = parser.parse_args()

    urls = list(args.urls)
    if args.file:
        with open(args.file) as f:
            data = json.load(f)
        for item in data.get("Likes and Favorites", {}).get("Like List", {}).get("ItemFavoriteList", []):
            link = item.get("Link") or item.get("link")
            if link:
                urls.append(link)

    os.makedirs(VIDEO_DIR, exist_ok=True)
    db = sqlite_utils.Database(DB_PATH)

    db['videos'].create({
        "video_id": str,
        "url": str,
        "video_path": str,
        "json_data": str
    }, pk='video_id', if_not_exists=True)
    db['transcripts'].create({
        "video_id": str,
        "timestamp": str,
        "transcript": str
    }, pk=('video_id', 'timestamp'), if_not_exists=True)
    db['conversations'].create({
        "conversation_id": str,
        "type": str,
        "display_name": str,
    }, pk='conversation_id', if_not_exists=True)
    db['messages'].create({
        "conversation_id": str,
        "date": str,
        "from_user": str,
        "content": str,
        "video_id": str,
    }, pk=('conversation_id', 'date', 'from_user'), if_not_exists=True,
    foreign_keys=[("conversation_id", "conversations"), ("video_id", "videos")])

    if args.file:
        def import_chats(chats, chat_type):
            for key, messages in chats.items():
                conversation_id = re.search(r'with (.+?):', key).group(1)
                db['conversations'].insert({
                    "conversation_id": conversation_id,
                    "type": chat_type,
                    "display_name": conversation_id if chat_type == "dm" else None,
                }, pk='conversation_id', replace=True)
                rows = []
                for msg in messages:
                    vid = video_id_from_content(msg["Content"])
                    rows.append({
                        "conversation_id": conversation_id,
                        "date": msg["Date"],
                        "from_user": msg["From"],
                        "content": msg["Content"],
                        "video_id": vid,
                    })
                db['messages'].insert_all(rows, pk=('conversation_id', 'date', 'from_user'), replace=True)
                print(f"Imported {len(rows)} messages from {key.strip(':')}")

        dm_chats = data.get("Direct Messages", {}).get("ChatHistory", {})
        import_chats(dm_chats, "dm")
        group_chats = data.get("Group Chat", {}).get("GroupChat", {})
        import_chats(group_chats, "group")

    if not urls and not args.file:
        parser.error("No URLs provided. Pass URLs as arguments or use -f with a JSON file.")

    for url in urls:
        print(f"Processing {url}...")
        video_id = extract_video_id(url)

        if db['videos'].count_where("video_id = ?", [video_id]) > 0:
            print(f"Skipping {url} as it already exists in the database.")
            continue

        if args.dry_run:
            video_path = os.path.join(VIDEO_DIR, f'{video_id}.mp4')
            srt_path = os.path.join(VIDEO_DIR, f'{video_id}.en.srt')
            if os.path.exists(video_path):
                print(f"  Would skip download (file exists): {video_path}")
            else:
                print(f"  Would download: {video_path}")
            if os.path.exists(srt_path):
                print(f"  Would skip transcription (file exists): {srt_path}")
            else:
                print(f"  Would transcribe: {srt_path}")
            print(f"  Would insert into database: {video_id}")
            continue

        video_path = download_video_and_metadata(video_id, url, VIDEO_DIR)

        if db['transcripts'].count_where("video_id = ?", [video_id]) > 0:
            print(f"Skipping transcription for {url} as transcripts already exist in the database.")
        else:
            extract_subtitles(video_id, VIDEO_DIR)

        load_into_database(video_id, url, video_path, VIDEO_DIR, db)
