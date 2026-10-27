// supabase/functions/_shared/providers/expert-search.ts — P2-S02-T02
// Busca em duas etapas na API Clínica Experts (SPEC P2-S02).
import { expertGet, lerPacienteMinimo, type ExpertPatientMin } from './clinica-experts.ts'

export type ClasseBusca = 'um' | 'multiplos' | 'provavel' | 'zero'
export type Candidato = ExpertPatientMin & { birth_masked: string | null }

export type HttpGetFn = (
  caminho: string,
  query: Record<string, string>,
) => Promise<{ status: number; data: unknown }>

export type BudgetLocal = { take: () => number; marcar: () => void }

/** Máscara do nascimento para a tela: ** / ** / 1990 (nunca dia/mês inteiros). */
export function mascararNascimento(birth: string | null): string | null {
  if (!birth || !/^\d{4}-\d{2}-\d{2}$/.test(birth)) return null
  return `**/**/${birth.slice(0, 4)}`
}

/** DDD de um E.164 BR (+55DD...); não-BR: 2 dígitos após o DDI. */
export function dddDe(e164: string): string | null {
  const m = e164.match(/^\+55(\d{2})/)
  if (m) return m[1]
  const m2 = e164.match(/^\+(\d{1,2})/)
  return m2 ? m2[1] : null
}

/** Busca em duas etapas com httpGet injetável (testável). */
export async function buscarEmDuasEtapasComHttp(
  phoneE164: string,
  httpGet: HttpGetFn,
  budget: BudgetLocal,
): Promise<{ result_class: ClasseBusca; candidatos: Candidato[] }> {
  const semMais = phoneE164.replace(/^\+/, '')
  // etapa (a): E.164 completo
  budget.take()
  const ra = await httpGet('patients', { phone: semMais, per_page: '10' })
  const listaA = Array.isArray(ra.data) ? ra.data : ((ra.data as { data?: unknown[] })?.data as unknown[]) ?? []
  const candidatosA = (listaA.map(lerPacienteMinimo).filter(Boolean) as ExpertPatientMin[]).map((c) => ({
    ...c,
    birth_masked: mascararNascimento(c.birth_date),
  }))
  if (candidatosA.length === 1) return { result_class: 'um', candidatos: candidatosA }
  if (candidatosA.length >= 2) return { result_class: 'multiplos', candidatos: candidatosA }

  // etapa (b): últimos 8 dígitos (números antigos sem o 9º dígito)
  const temNono = semMais.length >= 13 && /^55\d{2}9/.test(semMais)
  if (!temNono) return { result_class: 'zero', candidatos: [] }
  const ultimos8 = semMais.slice(-8)
  const ddd = dddDe(phoneE164)
  budget.take()
  const rb = await httpGet('patients', { phone: ultimos8, per_page: '50' })
  const listaB = Array.isArray(rb.data) ? rb.data : ((rb.data as { data?: unknown[] })?.data as unknown[]) ?? []
  const candidatosB = (listaB.map(lerPacienteMinimo).filter(Boolean) as ExpertPatientMin[])
    .filter((c) => c.phone_e164 && dddDe(c.phone_e164) === ddd)
    .map((c) => ({ ...c, birth_masked: mascararNascimento(c.birth_date) }))
  if (candidatosB.length >= 1) return { result_class: 'provavel', candidatos: candidatosB }
  return { result_class: 'zero', candidatos: [] }
}

/** Busca real (usa expertGet do módulo T01). */
export async function buscarEmDuasEtapas(
  baseUrl: string,
  token: string,
  phoneE164: string,
  opcoes: Record<string, unknown> = {},
): Promise<{ result_class: ClasseBusca; candidatos: Candidato[] }> {
  const budgetLocal = {
    take: () => 0,
    marcar: () => {},
  }
  return buscarEmDuasEtapasComHttp(phoneE164, async (caminho, query) => {
    const r = await expertGet(baseUrl, token, caminho, query, {
      correlationId: opcoes.correlationId as string,
    })
    return { status: r.status, data: r.data }
  }, budgetLocal)
}
