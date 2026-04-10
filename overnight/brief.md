# Overnight Brief

## Projects

- freqtrade: "Review and improve YujiStrategy — optimise entry/exit signals, add risk management, backtest"
- polymarket-bot: "Harden the bot — add error handling, improve logging, validate edge cases in trading logic"
- TLE: "Continue feature development — check PRD for next incomplete stories"

## Do NOT Touch

- freqtrade: "Don't modify docker-compose.yml or config.json credentials"
- polymarket-bot: "Don't change API keys or wallet config. Don't enable live trading."
- TLE: "Don't modify Supabase RLS policies or migration files"
- ALL: "Don't commit any secrets, API keys, or private keys"

## Constraints

- freqtrade: strategies must remain compatible with freqtrade stable Docker image
- polymarket-bot: keep dry-run mode as default — never auto-enable real trading
- All commits must be small and atomic with descriptive messages
- No new dependencies without clear justification
- If tests exist, they must pass after changes

## Context

- freqtrade runs via Docker, strategies are in user_data/strategies/
- polymarket-bot uses py-clob-client for Polymarket API access
- TLE uses Nuxt 4 + Vue 3 + Drizzle ORM, check prd.json for current stories
- All three are revenue-relevant projects (trading bots = direct, TLE = indirect)

## Success Looks Like

- freqtrade: YujiStrategy has improved signal logic with documented parameters
- polymarket-bot: all trading functions have proper error handling and logging
- TLE: at least 2 PRD stories moved forward
- All three: clean git logs, no broken builds
