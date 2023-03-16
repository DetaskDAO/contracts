pragma solidity ^0.8.0;

import "../interface/ITask.sol";
import "../interface/IOrder.sol";
import "../interface/IStage.sol";
import "../interface/IMetadata.sol";
import "../interface/IMetaComm.sol";
import "../libs/MyStrings.sol";
import "base64-sol/base64.sol";
import "../libs/uint12a4.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BuilderMetadata is IMetadata {
    using MyStrings for string;
    using uint12a4 for uint48;

    ITask public taskAddr;
    address public orderAddr;
    IMetaComm public metaComm;

    constructor(
        address _task,
        address _order,
        address _metaComm
    ) {
        taskAddr = ITask(_task);
        orderAddr = _order;

        metaComm = IMetaComm(_metaComm);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return generateTokenUri(tokenId);
    }

    function genAttributes(
        uint256 orderId,
        uint48 taskskills,
        string memory attachment
    ) internal view returns (string memory) {

        Order memory order = IOrder(orderAddr).getOrder(orderId);
        uint256 startTs = order.startDate;
        uint256 endTs = startTs + IStage(orderAddr).totalStagePeriod(orderId);

        string memory valueStr = metaComm.tokenAmountApprox(
            order.amount,
            order.token, 
            false
        );

        return
            string(
                abi.encodePacked(
                    metaComm.skillAttributes(taskskills, 0),
                    metaComm.skillAttributes(taskskills, 1),
                    metaComm.skillAttributes(taskskills, 2),
                    metaComm.skillAttributes(taskskills, 3),
                    '{"trait_type": "Amount",',
                    '"value": "',
                    valueStr,
                    '"},',
                    '{"trait_type": "Start",',
                    '"value": "',
                    metaComm.dateTime(startTs),
                    '"},',
                    '{"trait_type": "End",',
                    '"value": "',
                    metaComm.dateTime(endTs),
                    '"},',
                    '{"trait_type": "IPFS",',
                    '"value": "',
                    attachment,
                    '"}'
                )
            );
    }

    // refer: https://docs.opensea.io/docs/metadata-standards
    function generateTokenUri(uint256 orderId)
        internal
        view
        returns (string memory)
    {
        uint256 taskId;
        {
            Order memory order = IOrder(orderAddr).getOrder(orderId);
            taskId = order.taskId;
        }

        string memory svg = generateSVGBase64(generateSVG(taskId));
        (
            string memory title,
            string memory attachment,
            ,
            ,
            ,
            uint48 taskskills,
            ,

        ) = taskAddr.getTaskInfo(taskId);

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "DeTask Buidler #',
            Strings.toString(orderId),
            '",',
            '"title": "',
            title,
            '",',
            '"description": " More details on: https://detask.xyz/order/',
            Strings.toString(orderId),
            '",', // on ...
            '"image": "',
            svg,
            '",',
            '"attributes": [',
            genAttributes(orderId, taskskills, attachment),
            "]",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function skillSVGs(uint48 taskskills)
        internal
        view
        returns (string memory svgString)
    {
        uint256 pos = 36;
        string memory curSVG = "";
        for (uint256 i = 0; i < 4; i++) {
            (curSVG, pos) = skillSVG(taskskills, i, pos);
            svgString = string(abi.encodePacked(svgString, curSVG));
        }
    }

    function skillSVG(
        uint48 taskskills,
        uint256 i,
        uint256 posStart
    ) internal view returns (string memory svgString, uint256 pos) {
        uint256 skill = taskskills.get(i);
        if (skill > 0) {
            string memory label = metaComm.skills(skill);

            svgString = string(
                abi.encodePacked(
                    '<text class="c7" transform="translate(',
                    Strings.toString(posStart),
                    ' 146.48)">',
                    label,
                    "</text>"
                )
            );

            (uint256 slen, uint256 blen) = label.strlen();
            pos = posStart + slen * 5 + 10;
        } else {
            pos = posStart;
            svgString = "";
        }
    }

    function generateSVG(uint256 orderId)
        public
        view
        returns (bytes memory svg)
    {
        Order memory order = IOrder(orderAddr).getOrder(orderId);
        uint256 taskId = order.taskId;
        (
            string memory title,
            string memory attachment,
            ,
            ,
            ,
            uint48 taskskills,
            ,

        ) = taskAddr.getTaskInfo(taskId);

        string memory valueStr = metaComm.tokenAmountApprox(
            order.amount,
            order.token,
            true
        );

        return
            abi.encodePacked(
                '<svg id="l1" data-name="L1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 470 268">',
                "<defs>",
                '<linearGradient id="a4" x1="1.42" y1="134" x2="468.44" y2="134" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fee7b9"/><stop offset="1" stop-color="#c91d3b"/></linearGradient>',
                '<linearGradient id="b3" x1="298.21" y1="218.48" x2="329.4" y2="218.48" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#da0035"/><stop offset=".99" stop-color="#ff766e"/><stop offset="1" stop-color="#ff776f"/></linearGradient>',
                '<linearGradient id="b4" x1="298.21" y1="168.51" x2="457.31" y2="168.51" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#da0035"/><stop offset=".52" stop-color="#ed7575"/><stop offset="1" stop-color="#ffe6b2"/></linearGradient>',
                '<linearGradient id="b6" x1="292.21" y1="224.48" x2="323.4" y2="224.48" xlink:href="#b3"/>',
                '<linearGradient id="b5" x1="292.21" y1="174.51" x2="451.31" y2="174.51" xlink:href="#b4"/>',
                '<clipPath id="clip-path"><path d="M0 0h410.59A46.41 46.41 0 0 1 457 46.41v161.18A46.41 46.41 0 0 1 410.59 254H0V0Z" style="fill:none"/>    </clipPath>',
                "<style>.c6,.c7{fill:#fff;font-size:9.04px}.c6{font-family:PingFangSC-Light,PingFang SC}.c7{font-family:PingFangSC-Medium,PingFang SC}.c11{clip-path:url(#clip-path)}</style>",
                "</defs>",
                '<path style="fill:url(#a4)" d="M-.01 0h469.99v268H-.01z"/>',
                '<path d="M410.59 254H0V0h410.59A46.41 46.41 0 0 1 457 46.41v161.18A46.41 46.41 0 0 1 410.59 254Z" style="fill:#1f1e2e"/>',
                '<text transform="rotate(-90 126.725 93.275)" style="font-family:PingFangSC-Semibold,PingFang SC;fill:#fff;opacity:.2;font-size:41.17px;letter-spacing:.05em">BUILDER</text>',
                '<text transform="translate(11.97 71.69)" style="font-size:28.52px;font-family:PingFangSC-Semibold,PingFang SC;fill:#fff">',
                title,
                "</text>",
                '<text class="c6" transform="translate(36 132.92)">Skill:</text>',
                skillSVGs(taskskills),
                '<text class="c6" transform="translate(36 164.3)">Token ID:</text><text class="c7" transform="translate(36 176.96)">',
                Strings.toString(orderId),
                '</text><text class="c6" transform="translate(36 101.95)">Task:</text>  <text class="c7" transform="translate(36 115.6)">',
                attachment,
                '</text><text class="c6" transform="translate(36 195.23)">Amount:</text><text class="c7" transform="translate(36 207.89)">',
                valueStr,
                "</text>",
                '<g style="opacity:.5"><path d="M328.84 236.5a17 17 0 0 1-17 17h-13.07v-53.07a17 17 0 0 1 17-17h13.08Z" style="stroke:url(#b3);stroke-miterlimit:10;stroke-width:1.12px;fill:none"/> <path d="M373.76 83.52h-57.85a17.14 17.14 0 0 0-17.14 17.14v48.87h95.03a12.57 12.57 0 0 1 12.57 12.57v8.8a12.57 12.57 0 0 1-12.57 12.57h-31v70.06h11a83 83 0 0 0 83-83v-4a83 83 0 0 0-83.04-83.01Z" style="stroke:url(#b4);stroke-miterlimit:10;stroke-width:1.12px;fill:none"/></g>',
                '<path d="M322.84 242.5a17 17 0 0 1-17 17h-13.07v-53.07a17 17 0 0 1 17-17h13.08Z" style="stroke:url(#b6);stroke-miterlimit:10;stroke-width:1.12px;fill:none" class="c11"/>',
                '<path d="M367.76 89.52h-57.85a17.14 17.14 0 0 0-17.14 17.14v48.87h95.03a12.57 12.57 0 0 1 12.57 12.57v8.8a12.57 12.57 0 0 1-12.57 12.57h-31v70.06h11a83 83 0 0 0 83-83v-4a83 83 0 0 0-83.04-83.01Z" style="stroke:url(#b5);stroke-miterlimit:10;stroke-width:1.12px;fill:none" class="c11"/>',
                "</svg>"
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
