pragma solidity >=0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockedSale is Ownable {

    uint256 public minAmount = 0.01 ether;
    bool public saleActive = true;
    uint256 public price = 0.55 ether; // 1 RV2 = 0.55 BUSD

    IERC20 public payToken; // busd
    IERC20 public recvToken; // rv2


    constructor(IERC20 _payToken, IERC20 _recvToken) {
        payToken = _payToken;
        recvToken = _recvToken;
    }

    function swapToken(uint256 _amount) public onlySaleActive {
        require(_amount >= minAmount, "amount too low");
        uint256 busdBalance = getContractBalance();
        uint256 amountToPay = (_amount * price) / 1 ether;

        require(busdBalance >= amountToPay, "contract balance low");

        uint256 netAmount = netTransfer(payToken, msg.sender, _amount);

        uint256 netAmountToPay = (netAmount * price) / 1 ether;

        recvToken.transfer(msg.sender, netAmountToPay);

        emit Swap(msg.sender, netAmount, netAmountToPay);
    }

    // internal functions

    function netTransfer(IERC20 _token, address _from, uint256 _amount) internal returns(uint256) {
        uint256 before = _token.balanceOf(address(this));
        _token.transferFrom(_from, address(this), _amount);
        return _token.balanceOf(address(this)) - before;
    }

    // view functions

    function getContractBalance() public view returns(uint256) {
        return payToken.balanceOf(address(this));
    }

    // owner functions

    function toggleSaleStatus() public onlyOwner {
        saleActive = !saleActive;
    }

    function setMinAmount(uint256 _amount) public onlyOwner {
        minAmount = _amount;

        emit MinAmountChanged(_amount);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;

        emit PriceChanged(price);
    }

    function withdrawTokens(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    // modifiers

    modifier onlySaleActive {
        require(saleActive, "Sale is not active.");
        _;
    }

    event MinAmountChanged(uint256 amount);
    event ReceiverAddressChanged(address recv);
    event Swap(address indexed user, uint256 paid, uint256 sent);
    event PriceChanged(uint256 price);
}