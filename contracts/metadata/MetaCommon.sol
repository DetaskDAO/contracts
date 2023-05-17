pragma solidity ^0.8.0;

import "../libs/uint12a4.sol";
import "../libs/MyStrings.sol";
import "../libs/DateTimeLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
}


contract MetaCommon is Ownable {
    using MyStrings for string;
    using uint12a4 for uint48;

    mapping (uint => string) public currencyNames;
    mapping (uint => string) public skills;

    constructor() {

        currencyNames[1] = "USD";
        currencyNames[2] = "ETH";
        currencyNames[3] = "BNB";
        currencyNames[4] = "MATIC";
        currencyNames[5] = "OP";

        // l1 category 
        skills[1] = "Development";
        skills[2] = "Product";
        skills[3] = "Design";
        skills[4] = "Testing";
        skills[5] = "Writing";
        skills[6] = "Marketing";
        skills[7] = "Research";
        skills[8] = "Operation";
        skills[9] = "Translation";
        skills[10] = "Training";
        skills[11] = "Services";


        // l2 category:  skills
        skills[20] = "Web Frontend";
        skills[21] = "Backend";
        skills[22] = "Desktop Apps";
        skills[23] = "Android/iOS";
        skills[24] = "Auto/Bots";
        skills[25] = "Mini Program";
        skills[26] = "Full Stack";
        skills[27] = "DevOps";
        skills[28] = "Data Analysts";
        skills[29] = "Blockchain"; 
        skills[30] = "AI/ML";  


        // l2 category: Langs
        skills[40] = "JavaScript";
        skills[41] = "Python";
        skills[42] = "Java";
        skills[43] = "Golang";
        skills[44] = "Solidity";
        skills[45] = "Rust";
        skills[46] = "C/C++";
        skills[47] = "PHP";
        skills[48] = ".Net";
        skills[49] = "SQL";
        skills[50] = "Move";
        skills[51] = "HTML/CSS";

        skills[61] = "Hardhat";
        skills[62] = "Defi";
        skills[63] = "NFT";
        
        skills[64] = "Spring";
        skills[65] = "Laravel";
        skills[66] = "React";
        skills[67] = "Vue.js";
    }

    function setSkillLabels(uint[] memory indexs,  string[] memory labels) external onlyOwner {
        require(indexs.length == labels.length, "mismatch");
        for (uint i=0; i < indexs.length; i++ ) {
            skills[i] = labels[i];
        }
    }

    function setSkillLabel(uint skillIndex,  string memory label) external onlyOwner {
        skills[skillIndex] = label;
    }

    function setCurrencyNames(uint currencyIndex,  string memory label) external onlyOwner {
        currencyNames[currencyIndex] = label;
    }

    function skillAttributes(uint48 taskskills, uint i) external view returns (string memory) {
        require(i < 4, "index to big");
        uint skill = taskskills.get(i);
        if (skill > 0) {
            return string(
                    abi.encodePacked(
                    '{',
                    '"trait_type": "Skill",', 
                    '"value": "', skills[skill], '"'
                    '},'));
        } else {
            return "";
        }
    }

    function dateTime(uint ts) external pure returns (string memory datatime) {
        // block.timestamp
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = DateTimeLibrary.timestampToDateTime(ts);
        // Format: 2017-06-21T22:13:59+0800
        datatime = string(abi.encodePacked(Strings.toString(year),
            "-",
            month <10 ? "0": "",
            Strings.toString(month),
            "-",
            day <10 ? "0": "",
            Strings.toString(day),
            "T",
            hour <10 ? "0": "",
            Strings.toString(hour),
            ":",
            minute <10 ? "0": "",
            Strings.toString(minute),
            ":",
            second <10 ? "0": "",
            Strings.toString(second),
            "Z"));
    }

    function amountConvert(uint amount, uint dec, bool escape) internal pure returns (string memory budget) {
        uint base = 1 * 10 ** dec;
        uint base_d10 = base / 10;
        uint base_d100 = base / 100;
        uint base_d1000 = base / 1000;
        uint base_d10000 = base / 10000;

        if (amount / base > 0) {
            if(amount / base < 10) {
                uint digit = amount / base;
                uint b = (amount - (digit * base)) / base_d10;
                budget = string(abi.encodePacked(unicode"≈", Strings.toString(digit),
                ".",
                    Strings.toString(b)));
            } else {
                budget = string(abi.encodePacked(unicode"≈", Strings.toString(amount / base))); 
            }

        } else if (amount / base_d10 > 0) {
            uint b = amount / base_d10;
            uint b2 = (amount - (b * base_d10)) / base_d100;
            budget = string(abi.encodePacked(unicode"≈", "0.", Strings.toString(b), Strings.toString(b2)));
        } else if (amount / base_d100 > 0) {
            uint b = amount / base_d100;
            uint b2 = (amount - (b * base_d100)) / base_d1000;
            budget = string(abi.encodePacked(unicode"≈", "0.0", Strings.toString(b), Strings.toString(b2)));
        } else if (amount / base_d1000 > 0) {
            uint b = amount / base_d1000;
            uint b2 = (amount - (b * base_d1000)) / base_d10000;
            budget = string(abi.encodePacked(unicode"≈", "0.00", Strings.toString(b), Strings.toString(b2)));
        } else {
            if (escape) {
                budget = "&lt;0.001";
            } else {
                budget = "<0.001";
            }
            
        }
    }

    function tokenAmountApprox(uint amount, address token, bool escape) external view returns (string memory budget) {
        uint dec = 18;
        string memory symbol;
        if (token == address(0)) {
            if (block.chainid == 56 || block.chainid == 97) {
                symbol = "BNB";
            } else if (block.chainid == 137 || block.chainid == 80001) {
                symbol = "MATIC";
            } else {
                symbol = "ETH";
            }
        } else {
            dec = IERC20(token).decimals();
            symbol = IERC20(token).symbol();
        }
        
        if(amount == 0) {
            return "Negotiable";
        }
        
        budget = amountConvert(amount, 18, escape);
        return string(
                        abi.encodePacked(budget, " ",
                symbol));
    }

    // 
    function amountApprox(uint amount, uint8 currency, bool escape) external view returns (string memory budget) {
        if(amount == 0) {
            return "Negotiable";
        } 

        budget = amountConvert(amount, 18, escape);
        return string(
                    abi.encodePacked(budget, " ",
            currencyNames[currency]));
    }

}