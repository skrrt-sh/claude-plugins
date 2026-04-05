---
title: "Gitmojis Reference"
description: "Reference for the gitmoji catalog and common commit pairings used by the ship commit skill."
author: "skrrt-sh"
created: "2026-04-02"
updated: "2026-04-02"
version: "1.0.0"
status: "published"
tags: ["gitmoji", "conventional-commits", "reference", "github"]
category: "guide"
aliases: ["gitmojis", "gitmoji-reference"]
related:
  - "../SKILL.md"
  - "./commit-types.md"
refs:
  - https://github.com/vivaxy/vscode-conventional-commits
  - https://github.com/carloscuesta/gitmoji
audience: ["external-developers", "backend-team", "frontend-team"]
---

# Gitmojis Reference

> Reference for choosing gitmojis that complement conventional commit intent in the `ship:commit` workflow.

## Table of Contents

- [How To Use Them](#how-to-use-them)
- [High-Signal Pairings](#high-signal-pairings)
- [Catalog](#catalog)

This reference is extracted from the gitmoji dataset version used by
`vivaxy/vscode-conventional-commits`: `carloscuesta/gitmoji` v3.13.1.

## How To Use Them

- The gitmoji complements the conventional type; it does not replace it.
- Prefer gitmoji code form such as `:bug:` or `:sparkles:` to match the upstream extension default.
- Pick the gitmoji for the most visible change in the commit.
- If two gitmojis feel equally necessary, the commit is often doing too much.
- A `feat` commit often pairs with `:sparkles:`, but not always.
- A `fix` commit often pairs with `:bug:`, `:ambulance:`, `:adhesive_bandage:`, or `:lock:`.
- A `docs` commit usually pairs with `:memo:`.
- `:boom:` signals a breaking change and should usually be backed by a clear footer.

## High-Signal Pairings

| Intent | Common type | Common gitmoji |
| --- | --- | --- |
| New feature | `feat` | `:sparkles:` |
| Bug fix | `fix` | `:bug:` |
| Critical hotfix | `fix` | `:ambulance:` |
| Docs | `docs` | `:memo:` |
| Refactor | `refactor` | `:recycle:` |
| Performance | `perf` | `:zap:` |
| Tests | `test` | `:white_check_mark:` or `:test_tube:` |
| CI | `ci` | `:green_heart:` or `:construction_worker:` |
| Dependencies | `build` or `chore` | `:arrow_up:`, `:arrow_down:`, `:heavy_plus_sign:`, `:heavy_minus_sign:`, `:pushpin:` |
| Config | `build`, `ci`, or `chore` | `:wrench:` |
| Breaking change | depends | `:boom:` |

## Catalog

| Emoji | Code | Meaning | Semver |
| --- | --- | --- | --- |
| 🎨 | `:art:` | Improve structure / format of the code. | - |
| ⚡️ | `:zap:` | Improve performance. | patch |
| 🔥 | `:fire:` | Remove code or files. | - |
| 🐛 | `:bug:` | Fix a bug. | patch |
| 🚑️ | `:ambulance:` | Critical hotfix. | patch |
| ✨ | `:sparkles:` | Introduce new features. | minor |
| 📝 | `:memo:` | Add or update documentation. | - |
| 🚀 | `:rocket:` | Deploy stuff. | - |
| 💄 | `:lipstick:` | Add or update the UI and style files. | patch |
| 🎉 | `:tada:` | Begin a project. | - |
| ✅ | `:white_check_mark:` | Add, update, or pass tests. | - |
| 🔒️ | `:lock:` | Fix security issues. | patch |
| 🔐 | `:closed_lock_with_key:` | Add or update secrets. | - |
| 🔖 | `:bookmark:` | Release / Version tags. | - |
| 🚨 | `:rotating_light:` | Fix compiler / linter warnings. | - |
| 🚧 | `:construction:` | Work in progress. | - |
| 💚 | `:green_heart:` | Fix CI Build. | - |
| ⬇️ | `:arrow_down:` | Downgrade dependencies. | patch |
| ⬆️ | `:arrow_up:` | Upgrade dependencies. | patch |
| 📌 | `:pushpin:` | Pin dependencies to specific versions. | patch |
| 👷 | `:construction_worker:` | Add or update CI build system. | - |
| 📈 | `:chart_with_upwards_trend:` | Add or update analytics or track code. | patch |
| ♻️ | `:recycle:` | Refactor code. | - |
| ➕ | `:heavy_plus_sign:` | Add a dependency. | patch |
| ➖ | `:heavy_minus_sign:` | Remove a dependency. | patch |
| 🔧 | `:wrench:` | Add or update configuration files. | patch |
| 🔨 | `:hammer:` | Add or update development scripts. | - |
| 🌐 | `:globe_with_meridians:` | Internationalization and localization. | patch |
| ✏️ | `:pencil2:` | Fix typos. | patch |
| 💩 | `:poop:` | Write bad code that needs to be improved. | - |
| ⏪️ | `:rewind:` | Revert changes. | patch |
| 🔀 | `:twisted_rightwards_arrows:` | Merge branches. | - |
| 📦️ | `:package:` | Add or update compiled files or packages. | patch |
| 👽️ | `:alien:` | Update code due to external API changes. | patch |
| 🚚 | `:truck:` | Move or rename resources (e.g.: files, paths, routes). | - |
| 📄 | `:page_facing_up:` | Add or update license. | - |
| 💥 | `:boom:` | Introduce breaking changes. | major |
| 🍱 | `:bento:` | Add or update assets. | patch |
| ♿️ | `:wheelchair:` | Improve accessibility. | patch |
| 💡 | `:bulb:` | Add or update comments in source code. | - |
| 🍻 | `:beers:` | Write code drunkenly. | - |
| 💬 | `:speech_balloon:` | Add or update text and literals. | patch |
| 🗃️ | `:card_file_box:` | Perform database related changes. | patch |
| 🔊 | `:loud_sound:` | Add or update logs. | - |
| 🔇 | `:mute:` | Remove logs. | - |
| 👥 | `:busts_in_silhouette:` | Add or update contributor(s). | - |
| 🚸 | `:children_crossing:` | Improve user experience / usability. | patch |
| 🏗️ | `:building_construction:` | Make architectural changes. | - |
| 📱 | `:iphone:` | Work on responsive design. | patch |
| 🤡 | `:clown_face:` | Mock things. | - |
| 🥚 | `:egg:` | Add or update an easter egg. | patch |
| 🙈 | `:see_no_evil:` | Add or update a .gitignore file. | - |
| 📸 | `:camera_flash:` | Add or update snapshots. | - |
| ⚗️ | `:alembic:` | Perform experiments. | patch |
| 🔍️ | `:mag:` | Improve SEO. | patch |
| 🏷️ | `:label:` | Add or update types. | patch |
| 🌱 | `:seedling:` | Add or update seed files. | - |
| 🚩 | `:triangular_flag_on_post:` | Add, update, or remove feature flags. | patch |
| 🥅 | `:goal_net:` | Catch errors. | patch |
| 💫 | `:dizzy:` | Add or update animations and transitions. | patch |
| 🗑️ | `:wastebasket:` | Deprecate code that needs to be cleaned up. | patch |
| 🛂 | `:passport_control:` | Work on code related to authorization, roles and permissions. | patch |
| 🩹 | `:adhesive_bandage:` | Simple fix for a non-critical issue. | patch |
| 🧐 | `:monocle_face:` | Data exploration/inspection. | - |
| ⚰️ | `:coffin:` | Remove dead code. | - |
| 🧪 | `:test_tube:` | Add a failing test. | - |
| 👔 | `:necktie:` | Add or update business logic. | patch |
| 🩺 | `:stethoscope:` | Add or update healthcheck. | - |
| 🧱 | `:bricks:` | Infrastructure related changes. | - |
| 🧑‍💻 | `:technologist:` | Improve developer experience. | - |
| 💸 | `:money_with_wings:` | Add sponsorships or money related infrastructure. | - |
| 🧵 | `:thread:` | Add or update code related to multithreading or concurrency. | - |
| 🦺 | `:safety_vest:` | Add or update code related to validation. | - |
