// Diagnostic reproductions: PASS means the vulnerable behavior was reproduced.
// Uses generated test certificates and in-memory data only. No production requests.
import { assertEquals } from 'jsr:@std/assert@1';
import { chain, sign } from '../../supabase/functions/_shared/test_chain.ts';
import { verifyApplePurchase, handleAppleNotification, type EntitlementStore } from '../../supabase/functions/_shared/purchases.ts';

type Row = Parameters<EntitlementStore['upsert']>[0];
class MemoryStore implements EntitlementStore {
  row: Row | null = null;
  events = new Set<string>();
  ownerOf() { return Promise.resolve(this.row?.userId ?? null); }
  upsert(row: Row) { this.row = {...row}; return Promise.resolve(); }
  setStatus(_source: unknown, _tx: string, status: Row['status']) { if (this.row) this.row.status = status; return Promise.resolve(); }
  recordEvent(id: string) { const fresh = !this.events.has(id); this.events.add(id); return Promise.resolve(fresh); }
}
async function fixture() {
  const c = await chain();
  const store = new MemoryStore();
  const now = new Date();
  const ctx = {store, bundleId:'pl.audiokiddo.app', now, jws:{roots:[c.rootB64]}};
  const tx = (extra: Record<string, unknown> = {}) => sign({bundleId:ctx.bundleId, environment:'Production', signedDate:now.getTime(), transactionId:'test-tx',originalTransactionId:'test-original',productId:'pl.audiokiddo.pack.wyobraznia',appAccountToken:'parent-a',...extra},c.x5c,c.leafKey);
  return {c,store,ctx,tx,now};
}
Deno.test('AUDIT: an old valid transaction reactivates a refunded Apple purchase', async () => {
  const f = await fixture();
  const old = await f.tx();
  await verifyApplePurchase(f.ctx,'parent-a',old);
  const revoked = await f.tx({revocationDate:f.now.getTime()});
  const refund = await sign({notificationType:'REFUND',notificationUUID:'refund-1',signedDate:f.now.getTime(),data:{bundleId:f.ctx.bundleId,signedTransactionInfo:revoked}},f.c.x5c,f.c.leafKey);
  await handleAppleNotification(f.ctx,refund,'hash-refund');
  assertEquals(f.store.row?.status,'refunded');
  await verifyApplePurchase(f.ctx,'parent-a',old);
  assertEquals(f.store.row?.status,'active');
});
Deno.test('AUDIT: Sandbox purchase grants access without an environment setting', async () => {
  const f = await fixture();
  await verifyApplePurchase(f.ctx,'parent-a',await f.tx({environment:'Sandbox'}));
  assertEquals(f.store.row?.status,'active');
});
Deno.test('AUDIT: another caller can reassign a transaction bound to parent-a', async () => {
  const f = await fixture(); const tx = await f.tx();
  await verifyApplePurchase(f.ctx,'parent-a',tx);
  await verifyApplePurchase(f.ctx,'parent-b',tx);
  assertEquals(f.store.row?.userId,'parent-b');
});
Deno.test('AUDIT: duplicate old Apple notification mutates state before deduplication', async () => {
  const f=await fixture(); await verifyApplePurchase(f.ctx,'parent-a',await f.tx());
  const note=await sign({notificationType:'DID_RENEW',notificationUUID:'old-event',signedDate:f.now.getTime(),data:{bundleId:f.ctx.bundleId,signedTransactionInfo:await f.tx()}},f.c.x5c,f.c.leafKey);
  await handleAppleNotification(f.ctx,note,'old-hash');
  await f.store.setStatus('app_store','test-original','refunded');
  assertEquals(await handleAppleNotification(f.ctx,note,'old-hash'),'duplicate');
  assertEquals(f.store.row?.status,'active');
});
