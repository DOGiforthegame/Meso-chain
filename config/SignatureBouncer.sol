pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./RBAC.sol";
import "./ECRecovery.sol";



contract SignatureBouncer is Ownable, RBAC {
  using ECRecovery for bytes32;

  string public constant ROLE_BOUNCER = "bouncer";
  uint constant METHOD_ID_SIZE = 4;
  // signature size is 65 bytes (tightly packed v + r + s), but gets padded to 96 bytes
  uint constant SIGNATURE_SIZE = 96;

  
  modifier onlyValidSignature(bytes _signature)
  {
    require(isValidSignature(msg.sender, _signature));
    _;
  }

  
  modifier onlyValidSignatureAndMethod(bytes _signature)
  {
    require(isValidSignatureAndMethod(msg.sender, _signature));
    _;
  }

  
  modifier onlyValidSignatureAndData(bytes _signature)
  {
    require(isValidSignatureAndData(msg.sender, _signature));
    _;
  }

  
  function addBouncer(address _bouncer)
    public
    onlyOwner
  {
    require(_bouncer != address(0));
    addRole(_bouncer, ROLE_BOUNCER);
  }

  
  function removeBouncer(address _bouncer)
    public
    onlyOwner
  {
    removeRole(_bouncer, ROLE_BOUNCER);
  }

  
  function isValidSignature(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    return isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address)),
      _signature
    );
  }

  
  function isValidSignatureAndMethod(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    bytes memory data = new bytes(METHOD_ID_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

  
  function isValidSignatureAndData(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    require(msg.data.length > SIGNATURE_SIZE);
    bytes memory data = new bytes(msg.data.length - SIGNATURE_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

  
  function isValidDataHash(bytes32 _hash, bytes _signature)
    internal
    view
    returns (bool)
  {
    address signer = _hash
      .toEthSignedMessageHash()
      .recover(_signature);
    return hasRole(signer, ROLE_BOUNCER);
  }
}
