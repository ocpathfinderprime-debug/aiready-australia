export type OcPrimeEnvelope<T = unknown> = {
  id: string;
  source: 'aiready_audit';
  type: string;
  tenantId: string;
  occurredAt: string;
  payload: T;
  piiClass: 'none' | 'low' | 'sensitive';
  approvalRequired?: boolean;
};

export interface OcPrimeAdapter {
  emit<T>(event: OcPrimeEnvelope<T>): Promise<{ accepted: boolean; eventId: string }>;
  requestApproval<T>(event: OcPrimeEnvelope<T>): Promise<{ approvalId: string; status: 'pending' }>;
  getCommand(commandId: string): Promise<unknown>;
}
