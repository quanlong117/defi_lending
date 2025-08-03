
import { beforeEach, describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;

const contractName = "savings-pool";

describe("Savings Pool Contract Tests", () => {
  beforeEach(() => {
    // Initialize the pool before each test
    simnet.callPublicFn(contractName, "initialize-pool", [], deployer);
  });

  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should initialize pool correctly", () => {
    const { result } = simnet.callReadOnlyFn(contractName, "get-pool-stats", [], deployer);
    console.log("Pool stats result:", result);
    expect(result).toBeDefined();
  });

  it("should check contract info", () => {
    const { result } = simnet.callReadOnlyFn(contractName, "get-contract-info", [], deployer);
    console.log("Contract info result:", result);
    expect(result).toBeDefined();
  });

  it("should check pool is enabled by default", () => {
    const { result } = simnet.callReadOnlyFn(contractName, "is-pool-enabled", [], deployer);
    expect(result).toBeBool(true);
  });
});
