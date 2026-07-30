onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/U_CORESYSSERVICES0/CLK
add wave -noupdate /testbench/U_CORESYSSERVICES0/RESETN
add wave -noupdate /testbench/U_CORESYSSERVICES0/HCLK
add wave -noupdate /testbench/U_CORESYSSERVICES0/HRESETN
add wave -noupdate /testbench/U_CORESYSSERVICES0/HSEL
add wave -noupdate /testbench/U_CORESYSSERVICES0/HADDR
add wave -noupdate /testbench/U_CORESYSSERVICES0/HTRANS
add wave -noupdate /testbench/U_CORESYSSERVICES0/HSIZE
add wave -noupdate /testbench/U_CORESYSSERVICES0/HBURST
add wave -noupdate /testbench/U_CORESYSSERVICES0/HWRITE
add wave -noupdate /testbench/U_CORESYSSERVICES0/HWDATA
add wave -noupdate /testbench/U_CORESYSSERVICES0/HREADY
add wave -noupdate /testbench/U_CORESYSSERVICES0/HRDATA
add wave -noupdate /testbench/U_CORESYSSERVICES0/HRESP
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_ENABLE_REQ
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_CMDBYTE_REQ
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_OPTIONS_MODE
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_BUSY
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_STATUS_VALID
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_STATUS_RESP
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_DATA_WRDY
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_DATA_WVALID
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_DATA_W
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_DATA_RVALID
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_DATA_R
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_CMD_ERROR
add wave -noupdate -expand -group {Tamper Signals} /testbench/U_CORESYSSERVICES0/SERV_TAMPER_MSGVALID
add wave -noupdate -expand -group {Tamper Signals} /testbench/U_CORESYSSERVICES0/SERV_TAMPER_MSG
add wave -noupdate -group {PUF Signals} /testbench/U_CORESYSSERVICES0/SERV_PUF_SUBCMD
add wave -noupdate -group {PUF Signals} /testbench/U_CORESYSSERVICES0/SERV_PUF_KEYSIZE
add wave -noupdate -group {PUF Signals} /testbench/U_CORESYSSERVICES0/SERV_PUF_INKEYNUM
add wave -noupdate -group {PUF Signals} /testbench/U_CORESYSSERVICES0/SERV_PUFUSERKEYADDR
add wave -noupdate -group {PUF Signals} /testbench/U_CORESYSSERVICES0/SERV_USEREXTRINSICKEYADDR
add wave -noupdate -group {NRBG Signals} /testbench/U_CORESYSSERVICES0/SERV_NRBG_PRREQ
add wave -noupdate -group {NRBG Signals} /testbench/U_CORESYSSERVICES0/SERV_NRBG_LENGTH
add wave -noupdate -group {NRBG Signals} /testbench/U_CORESYSSERVICES0/SERV_NRBG_HANDLE
add wave -noupdate -group {NRBG Signals} /testbench/U_CORESYSSERVICES0/SERV_NRBG_ADDLENGTH
add wave -noupdate -group {DPA Signals} /testbench/U_CORESYSSERVICES0/SERV_DPA_PATH
add wave -noupdate -group {DPA Signals} /testbench/U_CORESYSSERVICES0/SERV_DPA_OPTYPE
add wave -noupdate -group {DPA Signals} /testbench/U_CORESYSSERVICES0/SERV_DPA_KEY
add wave -noupdate -group {Crypto Signals} /testbench/U_CORESYSSERVICES0/SERV_CRYPTO_NBLOCKS
add wave -noupdate -group {Crypto Signals} /testbench/U_CORESYSSERVICES0/SERV_CRYPTO_MODE
add wave -noupdate -group {Crypto Signals} /testbench/U_CORESYSSERVICES0/SERV_CRYPTO_LENGTH
add wave -noupdate -group {Crypto Signals} /testbench/U_CORESYSSERVICES0/SERV_CRYPTO_KEY
add wave -noupdate -group {Crypto Signals} /testbench/U_CORESYSSERVICES0/SERV_CRYPTO_IV
add wave -noupdate /testbench/U_CORESYSSERVICES0/SERV_SPIADDR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 fs} 0}
quietly wave cursor active 0
configure wave -namecolwidth 547
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {47750643496 fs}
