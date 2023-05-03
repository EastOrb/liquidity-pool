//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";


interface pool{
    function deposit(address tokenAddr,uint amount) external;
    function withdrawal(address token, uint256 amount) external;
    function swap(address from, address to, uint256 amount) external;
    function swapRates(address from, address to) external view returns (uint256);
    function balanceOf(address user, address token) external view returns (uint256);
}
contract Pool is pool{

    mapping(address => mapping(address => uint)) public balances;

    function deposit(address tokenAddr, uint amount) external{
        IERC20 token = IERC20(tokenAddr);
        require(token.balanceOf(msg.sender) >= amount, "You don't have enough tokens to swap with");
        if(token.allowance(msg.sender, address(this)) >= amount) token.transferFrom(msg.sender, address(this), amount);
        else {
            token.approve(address(this), 0);
            token.approve(address(this), amount);
            token.transferFrom(msg.sender, address(this), amount);
            balances[msg.sender][tokenAddr] += amount;      
        }
    }

    function withdrawal(address tokenAddr, uint amount) external{
        IERC20 token = IERC20(tokenAddr);
         require(balances[msg.sender][tokenAddr] >= amount,"user does not have enough deposit for this withdrawal");
        
        token.transfer(msg.sender, amount);
        balances[msg.sender][tokenAddr] -= amount;
    }

    function swapRates(address from, address to) view public returns (uint256){
        IERC20 fromToken = IERC20(from);
        IERC20 toToken = IERC20(to);

        require(fromToken.balanceOf(address(this)) != 0, "This token does not exist on this pool");
        require(toToken.balanceOf(address(this)) != 0, "this token does not exist on this pool");

        return fromToken.balanceOf(address(this))/toToken.balanceOf(address(this));
    } 

    function swap(address from, address to, uint amount ) external{
        IERC20 fromToken = IERC20(from);
        IERC20 toToken = IERC20(to);
        uint256 rates = swapRates(from, to);

        require(toToken.balanceOf(address(this)) >= amount*rates, "Not enough token on the contract for the transaction");
        require(fromToken.balanceOf(msg.sender) >= amount, "User does not have enough for this transaction");

        if(fromToken.allowance(msg.sender, address(this)) >= amount) {
                fromToken.transferFrom(msg.sender, address(this), amount);
                toToken.transferFrom(address(this), msg.sender, amount*rates);
            }

        else {
                fromToken.approve(address(this), 0);
                fromToken.approve(address(this), amount);
                fromToken.transferFrom(msg.sender, address(this), amount);
                toToken.transferFrom(address(this), msg.sender, amount*rates);
        }

    }

    function balanceOf(address user, address token) external view returns (uint256){
        return balances[user][token];
    }
}