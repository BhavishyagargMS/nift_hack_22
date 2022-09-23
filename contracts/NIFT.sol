// SPDX-License-Identifier: MIT


pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract PrettyAwesomeWords is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  struct Voucher {
      string name;
      string description;
      string bgHue;
      string textHue;
      string value;
      uint amount;
        address payable redeemer;
        bool isRedeemed;
   }
  
  mapping (uint256 => Voucher) public vouchers;
  
  constructor() ERC721("Pretty Awesome Words", "PWA") {}

  // public
  function mint(string memory _value, uint _amount, address payable _receiver) public payable {
    uint256 supply = totalSupply();
    require(supply + 1 <= 1000);

    if (msg.sender != owner()) {
      require(msg.value >= _amount);
    }
    
    Voucher memory newWord = Voucher(
        string(abi.encodePacked('PWA #', uint256(supply + 1).toString())), 
        "Test NFTs for Hack '22",
        randomNum(361, block.difficulty, supply).toString(),
        randomNum(361, block.timestamp, supply).toString(),
        _value,
        _amount,
        _receiver,
        false
        );
     
    vouchers[supply + 1] = newWord;
    _safeMint(_receiver, supply + 1);
  }

  function randomNum(uint256 _mod, uint256 _seed, uint _salt) public view returns(uint256) {
      uint256 num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }
  
  function buildImage(uint256 _tokenId) public view returns(string memory) {
      Voucher memory currentWord = vouchers[_tokenId];
      return Base64.encode(bytes(
          abi.encodePacked(
              '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
              '<rect height="500" width="500" fill="hsl(',currentWord.bgHue,', 50%, 25%)"/>',
              '<text x="50%" y="50%" dominant-baseline="middle" fill="hsl(',currentWord.textHue,', 100%, 80%)" text-anchor="middle" font-size="41">',currentWord.value,'</text>',
              '</svg>'
          )
      ));
  }
  
  function buildMetadata(uint256 _tokenId) public view returns(string memory) {
      Voucher memory currentWord = vouchers[_tokenId];
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentWord.name,
                          '", "description":"', 
                          currentWord.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}')))));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }

  /*function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }*/

  function redeemVoucher(uint256 _tokenId) public {
        Voucher memory card = vouchers[_tokenId];
        require(card.isRedeemed == false , "Voucher is already redeemed");
        card.isRedeemed = true;
        card.redeemer.transfer(card.amount);
    }
}