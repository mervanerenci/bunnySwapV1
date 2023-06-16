// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    address public tokenAddress;

    constructor(address _token) ERC20("BunnySwapV1", "xBUNY") {
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
    }


    ///////// EXTERNAL FUNCTIONS ///////////


    function addLiquidity(uint256 _tokenAmount) public payable {
        if (getReserve()==0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;

        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;

            require(tokenAmount >= _tokenAmount, "insuffiecent");


            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this));

            uint256 liquidity = (msg.value * totalSupply() / ethReserve);
            _mint(msg.sender, liquidity);
            return liquidity;
        }

    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
}

    function ethToTokenSwap(uint256 _minAmount) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );


        require(tokensBought >= _minAmount, "not expected amount");

        IERC20(tokenAdress).transfer(msg.sender, tokensBought);


    }

    function tokenToEthSwap(uint256 _tokenAmount, uint256 _minAmount) public payable {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokenAmount,
            tokenReserve,
            address(this).balance
        );

        require(_minAmount >= 0, " not expected amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        payable(msg.sender)transfer(ethBought);
    }






    ///////// VIEW FUNCTIONS ///////////




    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }


    function getTokenAmount(
        uint256 _ethSold
    ) public view returns(uint256) {
        require(_ethSold > 0, "invalid amount" );

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    
    function getEthAmount(
        uint256 _tokenSold
    ) public view returns(uint256) {
        require(_tokenSold > 0, "invalid amount" );

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns(uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;


    }


}