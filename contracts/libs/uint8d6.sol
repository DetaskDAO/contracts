// uint8d6.sol
library uint8d6 { // provides the equivalent of uint8[](31)
    uint constant bits = 8;
    uint constant elements = 6;
    uint constant lenBits = 5;
    // ensure that (bits * elements) <= (256 - lenBits)
    
    uint constant range = 1 << bits;
    uint constant max = range - 1;
    uint constant lenPos = 256 - lenBits;
    
    function length(uint va) internal pure returns (uint) {
        return va >> lenPos;
    }

    function setLength(uint va, uint len) internal pure returns
    (uint) {
        require(len <= elements);
        return (va & (type(uint).max >> lenBits)) | (len << lenPos);
    }

    function get(uint va, uint index) internal pure returns (uint) {
        require(index < (va >> lenPos), "over range");
        return (va >> (bits * index)) & max;
    }

    function set(uint va, uint index, uint value) internal pure 
    returns (uint) {
        require((index < (va >> lenPos)) && (value < range), "over range");
        index *= bits;
        return (va & ~(max << index)) | (value << index);
    }

    function push(uint va, uint value) internal pure returns (uint){
        uint len = va >> lenPos;
        require((len < elements) && (value < range), "over range");
        uint posBits = len * bits;
        va = (va & ~(max << posBits)) | (value << posBits);
        return (va & (type(uint).max >> lenBits)) | ((len + 1) << lenPos);
    }
}
