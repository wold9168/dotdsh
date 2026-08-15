/**
 * Shell ask-gate for the "带Shell鉴权的极简模式" preset.
 *
 * Every shell instruction in this preset runs in ask form: this plugin
 * registers a `tools/pre-execute` listener that returns `{ kind: 'ask' }` for
 * the shell tool (`bash` — the persistent shell registers under that name),
 * so each shell call is routed through the host approval service and executes
 * only after the user approves it (`allowed-once`); otherwise it is denied.
 * Every other tool call passes through untouched.
 *
 * The module ships with the preset directory (the composition row references
 * it by a relative specifier), so the gate travels with the preset copy. It
 * publishes no service, so it needs no isolate realm.
 */
export const name = 'shell-ask-gate'

export function apply(ctx) {
  ctx.on('tools/pre-execute', (exec, next) => {
    if (exec.name === 'bash' || exec.name === 'pwsh') {
      return {
        kind: 'ask',
        reason: '此模式要求每条 Shell 指令均以 ask 形式执行：请确认是否允许运行该命令。',
      }
    }
    return next()
  })
}
