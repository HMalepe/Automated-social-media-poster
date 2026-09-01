# AI Social Media Automated Posting Pipeline

[![CI](https://github.com/HMalepe/Automated-social-media-poster/actions/workflows/ci.yml/badge.svg)](https://github.com/HMalepe/Automated-social-media-poster/actions/workflows/ci.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)](https://github.com/HMalepe/Automated-social-media-poster/releases)

A lightweight Python pipeline that generates social content with AI and publishes to **X/Twitter, LinkedIn, YouTube, and TikTok** — with draft approval, deduplication, and free GitHub Actions scheduling.

```
generate  →  approve (optional)  →  publish  →  log / de-dup history
```

**Why this project?** Zero hosting cost, official platform APIs, dry-run by default, and a clean adapter pattern you can extend in minutes.

## Features

- **AI content generation** via OpenAI (`gpt-4o-mini`), with offline template fallback — works with zero API keys
- **Pluggable platform adapters** — `twitter`, `linkedin`, `youtube`, `tiktok`, `mock`
- **Video upload** — YouTube Shorts, TikTok, and images on X via `--media`
- **Draft / approval workflow** — review before publish, or auto-approve when ready
- **De-duplication** — SQLite history prevents duplicate posts
- **Scheduling** — JSON queue with stable `job_id` and per-entry intervals
- **Free GitHub Actions cron** — daily posting with cached scheduler state
- **Safe by default** — `PIPELINE_DRY_RUN=true` until you opt into live posting

## Supported platforms

| Platform | Text | Video / image | API |
|----------|------|---------------|-----|
| **X / Twitter** | ✅ | Images | tweepy |
| **LinkedIn** | ✅ | — | UGC Posts REST |
| **YouTube** | — | ✅ Videos / Shorts | Data API v3 |
| **TikTok** | — | ✅ | Content Posting API |

## Quick start

```bash
git clone https://github.com/HMalepe/Automated-social-media-poster.git
cd Automated-social-media-poster

pip install -e ".[dev]"
cp .env.example .env

# Try it — no API keys needed
python -m ai_social_pipeline post --topic "AI in marketing" --platform mock --auto-approve
python -m ai_social_pipeline history
```

## CLI commands

| Command | Description |
|---------|-------------|
| `generate` | Print AI copy without saving |
| `post` | Generate and save draft (or publish with `--auto-approve`) |
| `publish-media` | Upload an existing video/image |
| `drafts` / `approve` | Review workflow |
| `history` | View post log |
| `schedule-once` | Run due queue jobs once (cron / GHA) |
| `schedule` | Local polling scheduler loop |

```bash
# Text post with draft review
python -m ai_social_pipeline post --topic "Product launch" --platform twitter

# Video to YouTube
python -m ai_social_pipeline publish-media \
  --platform youtube --media clip.mp4 \
  --text "Weekly update #Shorts" --title "Week 1"

# Scheduled posting
cp data/content_queue.example.json data/content_queue.json
python -m ai_social_pipeline schedule-once
```

## Project layout

```
src/ai_social_pipeline/
├── cli.py                 # CLI entry point
├── config.py              # Environment / .env settings
├── content_generator.py   # OpenAI + offline templates
├── pipeline.py            # generate → approve → publish
├── scheduler.py           # Queue runner with persisted state
├── storage.py             # SQLite history, drafts, queue
└── platforms/             # twitter, linkedin, youtube, tiktok, mock
data/
├── content_queue.example.json        # Text posts (GHA default)
└── content_queue.video.example.json  # Video posts
.github/workflows/
├── ci.yml                 # Lint + tests
└── scheduled-posting.yml  # Daily cron
```

## Going live

1. Copy `.env.example` → `.env` and add credentials for your platforms.
2. Install integrations: `pip install -e ".[all]"`
3. Set `PIPELINE_DRY_RUN=false` when ready for real posts.
4. Keep `PIPELINE_AUTO_APPROVE=false` to review drafts, or set `true` for full automation.

### Platform credentials

| Platform | Setup |
|----------|--------|
| **X / Twitter** | [developer.x.com](https://developer.x.com) → `TWITTER_*` keys |
| **LinkedIn** | OAuth token + `LINKEDIN_AUTHOR_URN` |
| **YouTube** | Google Cloud → YouTube Data API v3 → `YOUTUBE_*` OAuth refresh token |
| **TikTok** | [developers.tiktok.com](https://developers.tiktok.com) → `TIKTOK_ACCESS_TOKEN` |

## GitHub Actions (free scheduling)

1. Add secrets under **Settings → Secrets and variables → Actions** (see `.env.example`).
2. Commit `data/content_queue.json` (copy from `content_queue.example.json`).
3. Workflow runs daily at **09:00 UTC** — [`.github/workflows/scheduled-posting.yml`](.github/workflows/scheduled-posting.yml).

| Setting | Default | Purpose |
|---------|---------|---------|
| `PIPELINE_DRY_RUN` | `true` | Safe until you flip to live |
| `PIPELINE_AUTO_APPROVE` | `false` | Require review unless overridden |
| Scheduler cache | on | Honors `interval_minutes` between runs |

**Test manually:** Actions → Scheduled posting → Run workflow (dry-run on by default).

## Extending

Add a platform adapter in `src/ai_social_pipeline/platforms/` and register it in `PLATFORM_REGISTRY`:

```python
class MyPlatform(Platform):
    name = "myplatform"

    def is_configured(self) -> bool:
        return bool(self._settings.my_platform_token)

    def publish(self, content: PostContent) -> PublishResult:
        ...
```

## Development

```bash
pip install -e ".[dev]"
pytest
ruff check src tests
```

Tests run fully offline — no network or credentials required.

## License

MIT — see [LICENSE](LICENSE).

## Changelog

### 0.3.0
- Audit hardening: safe GHA defaults, draft safety, `job_id` scheduler, TikTok chunked upload
- YouTube + TikTok adapters, video upload, GitHub Actions cron

### 0.2.0
- Initial multi-platform support (X, LinkedIn, YouTube, TikTok)

### 0.1.0
- Scaffold: AI generation, drafts, SQLite history, mock platform
