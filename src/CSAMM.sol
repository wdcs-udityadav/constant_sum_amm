// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CSAMM {
    IERC20 immutable token0;
    IERC20 immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalSupply;

    mapping(address => uint256) public balance;

    error InvalidToken();

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _updateReserves(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function _mint(address _to, uint256 _amount) private {
        balance[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balance[_from] -= _amount;
        totalSupply -= _amount;
    }

    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        if (_tokenIn != address(token0) && _tokenIn != address(token1)) revert InvalidToken();

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint256 amountIn = tokenIn.balanceOf(address(this)) - reserveIn;
        amountOut = (amountIn * 997) / 1000;

        (uint256 res0, uint256 res1) =
            isToken0 ? (reserveIn + _amountIn, reserveOut - amountOut) : (reserveOut - amountOut, reserveIn + amountIn);
        _updateReserves(res0, res1);

        tokenOut.transfer(msg.sender, amountOut);
        return amountOut;
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 token0In = token0.balanceOf(address(this)) - reserve0;
        uint256 token1In = token1.balanceOf(address(this)) - reserve1;

        if (totalSupply == 0) {
            shares = token0In + token1In;
        } else {
            shares = ((token0In + token1In) * totalSupply) / (reserve0 + reserve1);
        }
        require(shares > 0, "Zero shares!");
        _mint(msg.sender, shares);
        
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));

        return shares;
    }

    function removeLiquidity(uint256 _shares) external returns (uint256 amount0, uint256 amount1) {
        require(_shares > 0, "Invalid input!");

        amount0 = (_shares * reserve0) / totalSupply;
        amount1 = (_shares * reserve1) / totalSupply;

        _burn(msg.sender, _shares);
        _updateReserves(reserve0 - amount0, reserve1 - amount1);

        require(amount0 > 0 && amount1 > 0, "amount0 and amount1 must be greater than zero.");
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        return (amount0, amount1);
    }
}
