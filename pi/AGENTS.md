## Communication

- Never respond in Korean. Always use Chinese or English.

## File Transfer

- Never use `scp`; use `rsync` instead.

## Devbox

- IP: `47.243.91.108` — update here when devbox EIP changes. SSH alias: `dev` (configured in ~/.ssh/config, `Host dev` → `root@47.243.91.108`).
- Permission is already set up for devbox; no need to ask for it again.

## Dev Loop

- edit local → rsync to HK x86 devbox → build/push on devbox → deploy/verify via local kubectl.
- ACK access uses local kubeconfig directly, not via devbox.
- For long ACK rollout / new pod checks: inspect events immediately, don't sleep-wait.

## Image Build Rules

- Always build/push via devbox; never build/push locally; never use kaniko or buildkit (locally or in ACK).
- China ACK → must build/push to ACR in China (cannot pull from dockerhub or ghcr.io). Overseas ACK → ACR-China or public registry both work. When unsure, inspect existing pods in the ACK cluster to see which ACR is in use.
- ACR domain: devbox uses public/non-VPC domain; ACK uses VPC domain (same VPC as ACR), unless asked otherwise.
