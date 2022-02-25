// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/access/Roles.sol";
import "../node_modules/@openzeppelin/contracts/access/MinterRole.sol";

/* -------------- Implementing Necessary Contracts ---------------- */

  interface ITRC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool); //Query whether a certain interface is supported (interfaceID)
  }

  abstract contract ITRC721 is ITRC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); //Successful transferFrom and safeTransferFrom will trigger the Transfer event
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); //Approval event will be triggered after Approval is successful
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); //ApprovalForAll event will be triggered after setApprovalForAll succeeds

    function balanceOf(address owner) public virtual view returns (uint256 balance); //number of NFTs owned by the specified account
    function ownerOf(uint256 tokenId) public virtual view returns (address owner); //owner of the specified NFT
    function safeTransferFrom(address from, address to, uint256 tokenId) virtual public; //Transfer ownership of an NFT
    function transferFrom(address from, address to, uint256 tokenId) virtual public; //Transfer ownership of an NFT
    function approve(address to, uint256 tokenId) virtual public;  //Grant other people control of an NFT
    function getApproved(uint256 tokenId) public virtual view returns (address operator); //Query the authorization of a certain NFT
    function setApprovalForAll(address operator, bool _approved) virtual public; //Grant/recover control of all NFTs by a third party 
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool); //Query whether the operator is the authorized address of the owner
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) virtual public; //Transfer ownership of an NFT
  }

  abstract contract ITRC721Metadata is ITRC721 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function tokenURI(uint256 tokenId) external virtual view returns (string memory);
  }

  // RQ:: A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers. //
  /* If the return value is not bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)")) an exception will be thrown. */
  abstract contract ITRC721Receiver {
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual returns (bytes4);
  }

  contract TRC165 is ITRC165 {
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor () {
        _registerInterface(_INTERFACE_ID_TRC165);
    }
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "TRC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
  }

  contract TRC721 is Context, TRC165, ITRC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _TRC721_RECEIVED = 0x5175f878;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

/*  constructor () public {
        // register the supported interfaces to conform to TRC721 via TRC165
        _registerInterface(_INTERFACE_ID_TRC721);
    } */

    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "TRC721: balance query for the zero address");
        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "TRC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) override public {
        address owner = ownerOf(tokenId);
        require(to != owner, "TRC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "TRC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_exists(tokenId), "TRC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) override public {
        require(to != _msgSender(), "TRC721: approve to caller");
        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) override public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) override public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) override public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnTRC721Received(from, to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "TRC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnTRC721Received(address(0), to, tokenId, _data), "TRC721: transfer to non TRC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) virtual internal {
        require(to != address(0), "TRC721: mint to the zero address");
        require(!_exists(tokenId), "TRC721: token already minted");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner, uint256 tokenId) virtual internal {
        require(ownerOf(tokenId) == owner, "TRC721: burn of token that is not own");
        _clearApproval(tokenId);
        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);
        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) virtual internal {
        require(ownerOf(tokenId) == from, "TRC721: transfer of token that is not own");
        require(to != address(0), "TRC721: transfer to the zero address");
        _clearApproval(tokenId);
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    
    function isContract(address addr) internal view returns(bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool){
        if (!isContract(to)) {
            return true;
        }
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            ITRC721Receiver(to).onTRC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("TRC721: transfer to non TRC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _TRC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
  }

  contract TRC721Metadata is Context, TRC165, TRC721, ITRC721Metadata {
    string private _name; // Token name
    string private _symbol; // Token Symbol
    string private _baseURI; // Base URI
    mapping(uint256 => string) private _tokenURIs; // Optional mapping for token URIs
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f; 
 
/*  constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        // register the supported interfaces to conform to TRC721 via TRC165
        _registerInterface(_INTERFACE_ID_TRC721_METADATA);
    } */

    function name() external override view returns (string memory) {
        return _name;
    }

    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "TRC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "TRC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setBaseURI(string memory basedURI) internal {
        _baseURI = basedURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function _burn(address owner, uint256 tokenId) override internal {
        super._burn(owner, tokenId);
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
  }

  abstract contract TRC721MetadataMintable is TRC721Metadata, MinterRole {
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
      _mint(to, tokenId);
      _setTokenURI(tokenId, tokenURI);
      return true;
    }
  }

  contract TRC721Mintable is TRC721, MinterRole {
      function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function safeMint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _safeMint(to, tokenId);
        return true;
    }

    function safeMint(address to, uint256 tokenId, bytes memory _data) public onlyMinter returns (bool) {
        _safeMint(to, tokenId, _data);
        return true;
    }
  }

/* -------------- END of contracts Implementation ---------------- */


/* --------------------------------------- Main NFT Contract --------------------------------------- */

contract TRON_NFT is TRC721MetadataMintable {
    
}

/* --------------------------------------- END of Main NFT Contract --------------------------------------- */