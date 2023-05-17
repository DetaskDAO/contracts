pragma solidity ^0.8.0;

import "../interface/ITask.sol";
import "../interface/IMetadata.sol";
import "../interface/IMetaComm.sol";
import "../libs/MyStrings.sol";
import "base64-sol/base64.sol";
import "../libs/uint12a4.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract TaskMetadata is IMetadata {
    using MyStrings for string;
    using uint12a4 for uint48;

    ITask public taskAddr;
    IMetaComm public metaComm;

    constructor(address _task, address _metaComm) {
        taskAddr = ITask(_task);
        metaComm = IMetaComm(_metaComm);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return generateTokenUri(tokenId);
    }

    // refer: https://docs.opensea.io/docs/metadata-standards
    function generateTokenUri(uint taskId) internal view returns (string memory) {
        string memory svg = generateSVGBase64(generateSVG(taskId));
        (string memory title, string memory attachment, 
            uint8 currency, uint128 budget, ,uint48 taskskills, uint32 timestamp, )= taskAddr.getTaskInfo(taskId);

        string memory valueStr = metaComm.amountApprox(budget, currency, false);
        
        bytes memory dataURI = abi.encodePacked(
        '{',
            '"name": "DeTask #', Strings.toString(taskId), '",',
            '"title": "', title, '",',
            '"description": "Task details on: https://detask.xyz/task/' ,  Strings.toString(taskId) , '",'   // on ...
            '"image": "', svg, '",',
            '"attributes": [',
                    metaComm.skillAttributes(taskskills, 0),
                    metaComm.skillAttributes(taskskills, 1),
                    metaComm.skillAttributes(taskskills, 2),
                    '{"trait_type": "Created",', 
                    '"value": "', metaComm.dateTime(timestamp),
                    '"},',
                    '{"trait_type": "Amount",', 
                    '"value": "', valueStr,
                    '"},',
                    '{"trait_type": "IPFS",', 
                    '"value": "', attachment,
                    '"}',
            ']',
        '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }


    function skillSVGs(uint48 taskskills) internal view returns (string memory svgString){
        uint pos = 10;
        string memory curSVG = "";
        for(uint i = 0; i < 4; i++) {
            (curSVG, pos) = skillSVG(taskskills, i, pos);
            svgString = string(abi.encodePacked(svgString, curSVG));
        }
        
    }

    function skillSVG(uint48 taskskills, uint i, uint posStart) internal view returns (string memory svgString, uint pos) {
        uint skill = taskskills.get(i);
        if (skill > 0) {
            string memory label = metaComm.skills(skill);

            svgString = string(
                    abi.encodePacked(
                        '<text class="b1" transform="translate(',
                        Strings.toString(posStart),
                        ' 70.25)">',
                        metaComm.skills(skill),
                        '</text>'));

            (uint slen, uint blen) = label.strlen();

            pos = posStart + slen * 3 + 4;
        } else {
            pos = posStart;
            svgString = "";
        }
        
    }

    function generateSVG(uint taskId) internal view returns (bytes memory svg) {
        (string memory title, ,uint8 currency, uint128 budget, ,uint48 taskskills, uint32 timestamp,)= taskAddr.getTaskInfo(taskId);

        string memory dateStr = metaComm.dateTime(timestamp);
        string memory valueStr = metaComm.amountApprox(budget, currency, true);

        return abi.encodePacked(
                    '<svg id="l_1" data-name="l 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 147.98 99.64">',
                    '<defs><linearGradient id="a" x1="1074.54" y1="1581.87" x2="1074.55" y2="1456.31" gradientTransform="matrix(0 -1 -1 0 1595.1 1124.36)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#d3d9f7"/><stop offset="1" stop-color="#dff8fd"/></linearGradient>',
                    '<linearGradient id="d1" x1="-669.05" y1="1241.1" x2="-658.71" y2="1241.1" gradientTransform="matrix(0 1 1 0 -1228.87 694.87)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#d4dcf8"/><stop offset="1" stop-color="#999"/></linearGradient>',
                    '<style>.b1,.b2,.b3{isolation:isolate}.b1{font-size:4px}.b1,.b3{fill:#1f1e2e;font-family:PingFangSC-Medium,PingFang SC}.b1{letter-spacing:.09em}.b2,.b3{letter-spacing:.07em}.b2{font-size:3.4px;font-family:PingFangSC-Light,PingFang SC;fill:gray}.b3{font-size:5px}</style>',
                    '</defs>',
                    '<path fill="url(#a)" d="M0 99.64V0h148v99.64Z"/>',
                    '<text class="b3" transform="translate(10 17.25)">Detask.xyz</text><text class="b3" transform="translate(43 17.25)">#',
                    Strings.toString(taskId),
                    '</text>',
                    '<path d="m12.23 31.35-1.56-2.23-.53.76 2.09 3 2.09-3-.53-.76Zm0-3.29-1.56-2.23-.53.76 2.09 3 2.09-3-.53-.76Zm0 6.59-1.56-2.24-.53.76 2.09 3 2.09-2.94-.53-.82Z" style="fill:url(#d1)"/>',
                    '<text transform="translate(10 54.91)" style="font-size:12px;font-family:PingFangSC-Semibold,PingFang SC;letter-spacing:-.05em;fill:#1f1e2e">',
                    title,
                    '</text>',
                    '<text class="b2" transform="translate(10 65.07)">Skill:</text>',
                    skillSVGs(taskskills),
                    '<text class="b2" transform="translate(10 82.68)">Task budget:</text>',
                    '<text transform="translate(10.13 87.72)" style="letter-spacing:.08em;font-family:PingFangSC-Medium,PingFang SC;fill:#1f1e2e;font-size:4px;isolation:isolate">',
                    valueStr,
                    '</text>',
                    '<text transform="translate(87.53 87.86)" style="font-size:3.4px;font-family:PingFangSC-Light,PingFang SC;letter-spacing:.07em;fill:#1f1e2e;isolation:isolate">',
                    dateStr,
                    '</text>',
                    '</svg>'
                );
    }

    function generateSVGBase64(bytes memory svgFormat)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgFormat)
            )    
        );
    }

}