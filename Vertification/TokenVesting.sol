pragma solidity ^0.4.24;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  
  function release(ERC20 _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  
  function revoke(ERC20 _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

  
  function releasableAmount(ERC20 _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  
  function vestedAmount(ERC20 _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}
