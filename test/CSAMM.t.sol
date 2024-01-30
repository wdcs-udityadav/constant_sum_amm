// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CSAMM} from "../src/CSAMM.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";

contract CSAMMTest is Test {
    CSAMM public csamm;
    TokenA public tokenA;
    TokenB public tokenB;

    function setUp() public {
        tokenA = new TokenA(address(this));
        tokenB = new TokenB(address(this));

        csamm = new CSAMM(address(tokenA), address(tokenB));
    }

    function testAddLiquidity() public {
        address user = vm.addr(1);

        tokenA.mint(user, 500);
        tokenB.mint(user, 500);
        assertEq(tokenA.balanceOf(user), 500);
        assertEq(tokenB.balanceOf(user), 500);

        vm.startPrank(user);
        assertTrue(tokenA.approve(address(csamm), 100));
        assertTrue(tokenB.approve(address(csamm), 100));
        assertEq(csamm.addLiquidity(100,100),200);
        vm.stopPrank();
    }

    function testSwap() public {
        address user = vm.addr(1);

        assertEq(tokenA.balanceOf(user), 0);
        assertEq(tokenB.balanceOf(user), 0);
        tokenA.mint(user, 500);
        tokenB.mint(user, 500);
        assertEq(tokenA.balanceOf(user), 500);
        assertEq(tokenB.balanceOf(user), 500);


        vm.startPrank(user);
        assertTrue(tokenA.approve(address(csamm), 100));
        assertTrue(tokenB.approve(address(csamm), 100));
        assertEq(csamm.addLiquidity(100,100),200);

        assertEq(tokenA.balanceOf(user), 400);
        assertEq(tokenB.balanceOf(user), 400);
        tokenA.approve(address(csamm), 50);
        csamm.swap(address(tokenA), 50);
        assertEq(tokenA.balanceOf(user), 350);
        assertEq(tokenB.balanceOf(user), 449);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        address user = vm.addr(1);

        tokenA.mint(user, 500);
        tokenB.mint(user, 500);
        assertEq(tokenA.balanceOf(user), 500);
        assertEq(tokenB.balanceOf(user), 500);

        //add liquidity
        vm.startPrank(user);
        assertTrue(tokenA.approve(address(csamm), 100));
        assertTrue(tokenB.approve(address(csamm), 100));
        assertEq(csamm.addLiquidity(100,100),200);

        //remove liquidity
        (uint256 amount0, uint256 amount1) = csamm.removeLiquidity(100);
        assertEq(amount0, 50);
        assertEq(amount1, 50);
        assertEq(tokenA.balanceOf(user), 450);
        assertEq(tokenB.balanceOf(user), 450);


        vm.stopPrank();
    }
}
