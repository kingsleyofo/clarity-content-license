import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new content with subscription periods",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"),
                types.list([types.uint(1), types.uint(3), types.uint(12)])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can purchase subscription license with auto-renewal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"),
                types.list([types.uint(1), types.uint(3), types.uint(12)])
            ], deployer.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1),
                types.uint(1),
                types.bool(true)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can renew subscription license",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"), 
                types.list([types.uint(1), types.uint(3), types.uint(12)])
            ], deployer.address),
            Tx.contractCall('license-manager', 'purchase-license', [
                types.uint(1),
                types.uint(1),
                types.bool(true)
            ], wallet1.address),
            Tx.contractCall('license-manager', 'renew-license', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[2].result.expectOk().expectBool(true);
    }
});
