#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sqlite_utils
import os

VIDEO_DIR = "/media/storage/Backups/August/TikTok"
DB_PATH = "/media/storage/Backups/August/TikTok/tiktok.db"
WHISPER_BIN = "/home/august/.local/bin/whisper"

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

def find_key(data, *paths):
    for path in paths:
        result = data
        for key in path:
            if not isinstance(result, dict):
                break
            result = result.get(key)
            if result is None:
                break
        else:
            if result:
                return result
    return []

def download_video_and_metadata(video_id, url, output_dir):
    video_path = os.path.join(output_dir, f'{video_id}.mp4')
    if not os.path.exists(video_path):
        run_command(['yt-dlp', url, '--output', os.path.join(output_dir, '%(id)s.%(ext)s'), '--write-info-json'])
    return video_path

def extract_subtitles(video_id, output_dir):
    srt_path = os.path.join(output_dir, f'{video_id}.en.srt')
    if not os.path.exists(srt_path):
        run_command([WHISPER_BIN, "--fp16", "False", "--language", "en", "--model", "small", "--output_dir", output_dir,  os.path.join(output_dir, f'{video_id}.mp4')])
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
    parser.add_argument('-f', '--file', nargs='+', help='Path(s) to user_data_tiktok.json files to extract liked video URLs and conversations from.')
    parser.add_argument('-n', '--dry-run', action='store_true', help='List what would be done without downloading or modifying anything.')
    parser.add_argument('--no-download', action='store_true', help='Skip downloading videos, only import already downloaded files.')
    parser.add_argument('--no-transcribe', action='store_true', help='Skip whisper transcription.')
    args = parser.parse_args()

    urls = list(args.urls)
    if args.file:
        for file_path in args.file:
            print(f"Reading {file_path}...")
            with open(file_path) as f:
                data = json.load(f)
            # TikTok's export format has changed over time, so we check multiple paths
            likes = find_key(data,
                ["Likes and Favorites", "Like List", "ItemFavoriteList"],
                ["Your Activity", "Like List", "ItemFavoriteList"],
                ["Activity", "Like List", "ItemFavoriteList"],
            )
            for item in likes:
                link = item.get("Link") or item.get("link")
                if link:
                    urls.append(link)

    os.makedirs(VIDEO_DIR, exist_ok=True)
    db = sqlite_utils.Database(DB_PATH)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA synchronous=NORMAL")

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

        for file_path in args.file:
            with open(file_path) as f:
                data = json.load(f)
            dm_chats = find_key(data,
                ["Direct Message", "Direct Messages", "ChatHistory"],
                ["Direct Messages", "Chat History", "ChatHistory"],
            ) or {}
            import_chats(dm_chats, "dm")
            group_chats = find_key(data,
                ["Direct Message", "Group Chat", "GroupChat"],
            ) or {}
            import_chats(group_chats, "group")

    if not urls and not args.file:
        parser.error("No URLs provided. Pass URLs as arguments or use -f with a JSON file.")

    existing_videos = {row[0] for row in db.execute("SELECT video_id FROM videos").fetchall()}
    local_files = {f[:-4] for f in os.listdir(VIDEO_DIR) if f.endswith('.mp4')}
    print(f"Found {len(existing_videos)} videos in database, {len(local_files)} files on disk.")

    # Filter to only new videos
    new_videos = []
    total = len(urls)
    for i, url in enumerate(urls, 1):
        if args.no_download:
            video_id = video_id_from_content(url)
            if not video_id:
                continue
        else:
            video_id = extract_video_id(url)
        if video_id in existing_videos:
            continue
        existing_videos.add(video_id)
        new_videos.append((video_id, url))
        if i % 500 == 0:
            print(f"  Checked {i}/{total} URLs...")

    if not new_videos:
        if urls:
            print("All videos already in database.")
        exit()

    print(f"Found {len(new_videos)} new videos to process.")

    if args.dry_run:
        for video_id, url in new_videos:
            if args.no_download:
                if video_id in local_files:
                    print(f"  Already downloaded: {video_id}.mp4")
                else:
                    print(f"  Not downloaded, skipping: {video_id}")
            else:
                if video_id in local_files:
                    print(f"  Would skip download (file exists): {video_id}.mp4")
                else:
                    print(f"  Would download: {video_id}.mp4")
            if not args.no_transcribe:
                srt_path = os.path.join(VIDEO_DIR, f'{video_id}.en.srt')
                if os.path.exists(srt_path):
                    print(f"  Would skip transcription (file exists): {srt_path}")
                else:
                    print(f"  Would transcribe: {srt_path}")
            print(f"  Would insert into database: {video_id}")
        exit()

    # Phase 1: Download
    if not args.no_download:
        urls_to_download = [url for vid, url in new_videos
                            if vid not in local_files]
        if urls_to_download:
            print(f"Downloading {len(urls_to_download)} videos...")
            subprocess.run(['yt-dlp', '--output', os.path.join(VIDEO_DIR, '%(id)s.%(ext)s'),
                            '--write-info-json', *urls_to_download])

    # Phase 2: Transcribe
    if not args.no_transcribe:
        for video_id, url in new_videos:
            if db['transcripts'].count_where("video_id = ?", [video_id]) > 0:
                print(f"Skipping transcription for {video_id} (already in database)")
                continue
            extract_subtitles(video_id, VIDEO_DIR)

    # Phase 3: Insert into database
    imported = 0
    skipped = 0
    for video_id, url in new_videos:
        if video_id not in local_files:
            skipped += 1
            continue
        video_path = os.path.join(VIDEO_DIR, f'{video_id}.mp4')
        load_into_database(video_id, url, video_path, VIDEO_DIR, db)
        imported += 1
        if imported % 100 == 0:
            print(f"  Inserted {imported} so far...")
    print(f"Imported {imported} videos into database ({skipped} not on disk)")

    db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
