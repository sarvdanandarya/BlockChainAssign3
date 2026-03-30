pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract SimpleDEX is ERC20 {

    // Token contracts
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Internal reserves
    uint public reserveA;
    uint public reserveB;

    // Constructor sets token addresses and LP token name
    constructor(address _tokenA, address _tokenB)
        ERC20("LP Token", "LPT")
    {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // ============================================================
    // 4.1.1 LIQUIDITY POOL & LP TOKENS
    // ============================================================

    /*
        Add liquidity to the pool
        - First user sets ratio
        - Later users must maintain ratio
        - LP tokens minted proportional to contribution
    */
    function addLiquidity(uint amountA, uint amountB) external {

        // Enforce ratio (for subsequent deposits)
        if (reserveA > 0 && reserveB > 0) {
            require(
                reserveA * amountB == reserveB * amountA,
                "Ratio must be preserved"
            );
        }

        // Transfer tokens from user → contract
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint shares;

        // First liquidity provider
        if (totalSupply() == 0) {
            // sqrt(x * y) gives fair initial shares
            shares = sqrt(amountA * amountB);
        } 
        else {
            // Mint shares proportional to contribution
            shares = min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        // Mint LP tokens
        _mint(msg.sender, shares);

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;
    }

    /*
        Remove liquidity
        - Burns LP tokens
        - Returns proportional share of reserves
    */
    function removeLiquidity(uint shares) external {

        require(shares > 0, "Invalid share amount");

        // Calculate proportional withdrawal
        uint amountA = (shares * reserveA) / totalSupply();
        uint amountB = (shares * reserveB) / totalSupply();

        // Burn LP tokens
        _burn(msg.sender, shares);

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back to user
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    // ============================================================
    // 4.1.2 SWAPPING MECHANISM (x * y = k)
    // ============================================================

    /*
        Swap TokenA → TokenB
        - Applies 0.3% fee
        - Maintains x * y = k
    */
    function swapAforB(uint amountA) external returns (uint amountB) {

        require(amountA > 0, "Invalid input");

        // Transfer TokenA from user
        tokenA.transferFrom(msg.sender, address(this), amountA);

        // Apply 0.3% fee (997 / 1000)
        uint amountAWithFee = (amountA * 997) / 1000;

        // Constant product formula
        uint newReserveA = reserveA + amountAWithFee;
        uint newReserveB = (reserveA * reserveB) / newReserveA;

        // Output amount
        amountB = reserveB - newReserveB;

        require(amountB > 0, "Insufficient output");

        // Transfer TokenB to user
        tokenB.transfer(msg.sender, amountB);

        // Update reserves
        reserveA += amountAWithFee;
        reserveB -= amountB;
    }

    /*
        Swap TokenB → TokenA
    */
    function swapBforA(uint amountB) external returns (uint amountA) {

        require(amountB > 0, "Invalid input");

        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint amountBWithFee = (amountB * 997) / 1000;

        uint newReserveB = reserveB + amountBWithFee;
        uint newReserveA = (reserveA * reserveB) / newReserveB;

        amountA = reserveA - newReserveA;

        require(amountA > 0, "Insufficient output");

        tokenA.transfer(msg.sender, amountA);

        reserveB += amountBWithFee;
        reserveA -= amountA;
    }

    // ============================================================
    // 4.1.3 TRACKING METRICS
    // ============================================================

    /*
        Returns current reserves
    */
    function getReserves() external view returns (uint, uint) {
        return (reserveA, reserveB);
    }

    /*
        Spot price of TokenA in terms of TokenB
        price = reserveB / reserveA
    */
    function getPriceA() external view returns (uint) {
        require(reserveA > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }

    /*
        Spot price of TokenB in terms of TokenA
    */
    function getPriceB() external view returns (uint) {
        require(reserveB > 0, "No liquidity");
        return (reserveA * 1e18) / reserveB;
    }

    // ============================================================
    // 4.1.4 SECURITY & VALIDATIONS
    // ============================================================

    /*
        Security measures implemented:
        - require() checks for invalid inputs
        - prevents zero-value swaps
        - ratio validation for liquidity
        - avoids division by zero
        - uses Solidity 0.8+ (auto overflow protection)
        - controlled token transfers (transferFrom)
    */

    // Helper: minimum of two numbers
    function min(uint x, uint y) private pure returns (uint) {
        return x < y ? x : y;
    }

    // Helper: square root (used for LP token calculation)
    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
