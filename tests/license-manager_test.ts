import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new content",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can purchase license",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium")
            ], deployer.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can verify license status",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium")
            ], deployer.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1)
            ], wallet1.address),
            Tx.contractCall('license-manager', 'has-valid-license', [
                types.uint(1),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block.receipts[2].result.expectOk().expectBool(true);
    }
});
