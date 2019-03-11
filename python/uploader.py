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
# ~ size = 1024

class NetWorker:
    def __init__(self, host, port):
        self.is_connected = 0
        self.host = host
        self.port = port
        self.soc = 0

    def Open(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect(( self.host,self.port))
            s.settimeout(5)
            self.is_connected = 1
            self.soc = s
        except:
            print("Can not connect\n")

    def Close(self):
        self.soc.close()
        self.is_connected = 0

    # ~ def make_conection(self):
        # ~ self.conn = self.Open(host, port)

    # TODO
    def SendData(self, data):
        if self.is_connected:
            self.soc.send(data)
        else:
            print "No connection"

    def Write_bin_Data(self, conn, intValue):
        size = 8
        value = bin(intValue).split('0b')[1].zfill(size) #Convert from int to binary string
        conn.send(value + '\n') #Newline is required to flush the buffer on the Tcl server

    # TODO
    def ReceiveData(self, soc, length):
        if self.is_connected:
            data = ''
            while len(data) < length:
                try:
                    more = soc.recv(length - len(data))
                except socket.timeout: # No more to read
                    break
                data += more
            return data
        else:
            print "No connection available"


class Uploader(QWidget):
    def __init__(self, parent = None):
        super(Uploader, self).__init__(parent)

        #Network Manager
        self.NetMgr = NetWorker(host, port)

        #Data buffer
        self.data = ''

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
        main_l.addStretch()

        # Events
        self.connectButton.clicked.connect(self.ManageConn)
        self.browseFileButton.clicked.connect(self.OpenFile)
        self.sendButton.clicked.connect(self.SendFile)

    def ManageConn(self):
        if self.NetMgr.is_connected:
            # is calling for connect
            self.NetMgr.Close()
            self.connectButton.setText(" Connect ")
        else:
            # is calling for disconnect
            self.NetMgr.Open()
            if self.NetMgr.is_connected:
                self.connectButton.setText("Disconnect")

    def OpenFile(self):
        options = QFileDialog.Options()
        # ~ if not self.native.isChecked():
            # ~ options |= QFileDialog.DontUseNativeDialog
        fileName, _ = QFileDialog.getOpenFileName(self,
                "Open app files to send", self.fileInLine.text(),
                "Bin Files (*.bin)", options=options)
        if fileName:
            self.fileInLine.setText(fileName)
            a = open(fileName, 'rb')
            self.data = str(a.read())

    # TODO
    def SendFile(self):
        # We send the file only if there are connection to JTAG tcl server
        if not self.NetMgr.is_connected:
            self.successLabel.setStyleSheet("QWidget { background-color: red }")
            self.successLabel.setText("No connection found")
            return

        print self.NetMgr.soc.recv(150)

        if len(self.data) > 0:
            for i in range(len(self.data)):
                #send data[i] and update progress bar
                self.NetMgr.SendData(self.data[i])
                print self.NetMgr.soc.recv(16)
                self.progress.setValue(((1+i)*100)/len(self.data))

            # Is done.
            self.NetMgr.SendData('E')
            self.NetMgr.SendData('N')
            self.NetMgr.SendData('D')

            self.successLabel.setStyleSheet("QWidget { background-color: green }")
            self.successLabel.setText(" Success ")
        else:
            self.successLabel.setStyleSheet("QWidget { background-color: red }")
            self.successLabel.setText("File no found")


def main():
    app = QApplication(sys.argv)
    ex = Uploader()
    ex.show()
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
