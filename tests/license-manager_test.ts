import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
    name: "Can toggle contract pause state",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'toggle-contract-pause', [], deployer.address),
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"),
                types.list([types.uint(1), types.uint(3), types.uint(12)])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(107);
    }
});

Clarinet.test({
    name: "Can remove content as owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('license-manager', 'register-content', [
                types.uint(1000),
                types.ascii("premium"),
                types.list([types.uint(1), types.uint(3), types.uint(12)])
            ], deployer.address),
            Tx.contractCall('license-manager', 'remove-content', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});
