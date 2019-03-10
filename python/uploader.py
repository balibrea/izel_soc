#####################################################################################
# Camaguey University Electromechanic Faculty, Electric Engineering Department      #
# ALTERA Cyclone II JTAG app uploader for IZEL FPGA soc.   10/3/2019 2:20PM         #
# Copyright (C) 2018 Yosel de Jesus Balibrea Lastre <yosel.balibrea@reduc.edu.cu>   #
#                                                                                   #
# This program is free software: you can redistribute it and/or modify it under     #
# the terms of the GNU General Public License as published by the Free Software     #
# Foundation, either version 3 of the License, or (at your option) any later        #
# version.                                                                          #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY   #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A   #
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.         #
#                                                                                   #
# You should have received a copy of the GNU General Public License along with this #
# program.  If not, see <http://www.gnu.org/licenses/>.                             #
#                                                                                   #
#####################################################################################

import socket

import sys
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.QtWidgets import *


host = 'localhost'
port = 2323
size = 1024

class NetWorker:
    def __init__(self):
        self.is_connected = 0

    def Open(self, host, port):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(( host,port))
        self.is_connected = 1
        return s

    def make_conection(self):
        self.conn = self.Open(host, port)

    def Write_bin_Data(self, conn, intValue):
        size = 8
        value = bin(intValue).split('0b')[1].zfill(size) #Convert from int to binary string
        conn.send(value + '\n') #Newline is required to flush the buffer on the Tcl server

    def ReceiveData(self):
        pass


class Uploader(QWidget):
    def __init__(self, parent = None):
        super(Uploader, self).__init__(parent)

        #Network Manager
        self.NetMgr = NetWorker()

        #Main Layout
        butt_l = QHBoxLayout()
        butt_l2 = QHBoxLayout()
        main_l = QVBoxLayout(self)

        self.connectButton = QPushButton(" Connect ")
        self.browseFileButton = QPushButton(" Browse ")
        self.sendButton = QPushButton(" Send ")
        self.fileInLine = QLineEdit()
        self.successLabel = QLabel()
        self.progress = QProgressBar()
        self.progress.setMaximum(100)

        #Ad items to layouts
        butt_l.addWidget(self.connectButton)
        butt_l.addWidget(self.fileInLine)
        butt_l.addWidget(self.browseFileButton)
        butt_l.addStretch()

        butt_l2.addWidget(self.sendButton)
        butt_l2.addWidget(self.progress)
        butt_l2.addWidget(self.successLabel)
        butt_l2.addStretch()

        main_l.addLayout(butt_l)
        main_l.addLayout(butt_l2)

        # Events
        self.connectButton.clicked.connect(self.ManageConn)
        self.browseFileButton.clicked.connect(self.OpenFile)
        self.sendButton.clicked.connect(self.SendFile)

    # TODO
    def ManageConn(self):
        if self.NetMgr.is_connected:
            # is calling for connect
            self.connectButton.setText(" Connect ")
        else:
            # is calling for disconnect
            self.connectButton.setText("Disconnect")

    # TODO
    def OpenFile(self):
        options = QFileDialog.Options()
        # ~ if not self.native.isChecked():
            # ~ options |= QFileDialog.DontUseNativeDialog
        fileName, _ = QFileDialog.getOpenFileName(self,
                "Open app files to send", self.fileInLine.text(),
                "Bin Files (*.bin)", options=options)
        if fileName:
            self.fileInLine.setText(fileName)

    # TODO
    def SendFile(self):
        self.successLabel.setStyleSheet("QWidget { background-color: green }")
        self.progress.setValue(100)
        self.successLabel.setText(" Success ")



def main():
    app = QApplication(sys.argv)
    ex = Uploader()
    ex.show()
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
