// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BusinessEscrow {
    address public owner;
    uint256 public invoiceCounter;

    enum InvoiceStatus { Pending, Paid }

    struct Invoice {
        uint256 id;
        string invoiceRef;
        address payable payee;
        address payer;
        uint256 amount;
        InvoiceStatus status;
    }

    mapping(uint256 => Invoice) public invoices;

    event InvoiceCreated(uint256 indexed id, string invoiceRef, address indexed payee, uint256 amount);
    event InvoiceSettled(uint256 indexed id, address indexed payer, uint256 amount);

    constructor() {
        owner = msg.sender;
        invoiceCounter = 0;
    }

    // 1. Write Function: Create Invoice
    function createInvoice(string memory _invoiceRef, address payable _payee, uint256 _amountInWei) public returns (uint256) {
        require(_payee != address(0), "Invalid payee address");
        require(_amountInWei > 0, "Amount must be > 0");

        invoiceCounter++;
        invoices[invoiceCounter] = Invoice({
            id: invoiceCounter,
            invoiceRef: _invoiceRef,
            payee: _payee,
            payer: address(0),
            amount: _amountInWei,
            status: InvoiceStatus.Pending
        });

        emit InvoiceCreated(invoiceCounter, _invoiceRef, _payee, _amountInWei);
        return invoiceCounter;
    }

    // 2. Write Function (Payable): Pay Invoice
    function payInvoice(uint256 _id) public payable {
        Invoice storage inv = invoices[_id];
        require(inv.id != 0, "Invoice not found");
        require(inv.status == InvoiceStatus.Pending, "Already paid");
        require(msg.value == inv.amount, "Incorrect ETH amount sent");

        inv.payer = msg.sender;
        inv.status = InvoiceStatus.Paid;

        (bool sent, ) = inv.payee.call{value: msg.value}("");
        require(sent, "ETH transfer failed");

        emit InvoiceSettled(_id, msg.sender, msg.value);
    }

    // 3. Read Function: Get Invoice Details
    function getInvoice(uint256 _id) public view returns (
        uint256 id,
        string memory invoiceRef,
        address payee,
        address payer,
        uint256 amount,
        InvoiceStatus status
    ) {
        Invoice memory inv = invoices[_id];
        require(inv.id != 0, "Invoice not found");
        return (inv.id, inv.invoiceRef, inv.payee, inv.payer, inv.amount, inv.status);
    }

    // 4. Read Function: Get Total Invoice Count
    function getInvoiceCount() public view returns (uint256) {
        return invoiceCounter;
    }
}