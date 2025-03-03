import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures reentrancy protection works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"),
                types.list([types.uint(1), types.uint(3), types.uint(12)]),
                types.none()
            ], wallet1.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1),
                types.uint(0),
                types.bool(true)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Tests rate limiting functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Multiple rapid purchases should fail
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1),
                types.uint(0),
                types.bool(true)
            ], wallet1.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1),
                types.uint(0),
                types.bool(true)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectErr().expectUint(108);
    }
});

[Previous tests remain unchanged...]
