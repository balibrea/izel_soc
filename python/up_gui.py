# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file './uploader.ui'
#
# Created by: PyQt5 UI code generator 5.10.1
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Main(object):
    def setupUi(self, Main):
        Main.setObjectName("Main")
        Main.resize(565, 412)
        Main.setMinimumSize(QtCore.QSize(565, 412))
        Main.setMaximumSize(QtCore.QSize(565, 412))
        self.widget = QtWidgets.QWidget(Main)
        self.widget.setGeometry(QtCore.QRect(20, 20, 531, 371))
        self.widget.setObjectName("widget")
        self.MainLay = QtWidgets.QVBoxLayout(self.widget)
        self.MainLay.setSizeConstraint(QtWidgets.QLayout.SetDefaultConstraint)
        self.MainLay.setContentsMargins(0, 0, 0, 0)
        self.MainLay.setObjectName("MainLay")
        self.textEdit = QtWidgets.QTextEdit(self.widget)
        self.textEdit.setStyleSheet("color: rgb(115, 210, 22);\n"
"background-color: rgb(0, 0, 0);\n"
"")
        self.textEdit.setObjectName("textEdit")
        self.MainLay.addWidget(self.textEdit)
        self.ContLay = QtWidgets.QHBoxLayout()
        self.ContLay.setObjectName("ContLay")
        self.vertLay1 = QtWidgets.QVBoxLayout()
        self.vertLay1.setObjectName("vertLay1")
        self.connButt = QtWidgets.QPushButton(self.widget)
        self.connButt.setObjectName("connButt")
        self.vertLay1.addWidget(self.connButt)
        self.sendButt = QtWidgets.QPushButton(self.widget)
        self.sendButt.setObjectName("sendButt")
        self.vertLay1.addWidget(self.sendButt)
        self.ContLay.addLayout(self.vertLay1)
        self.vertLay2 = QtWidgets.QVBoxLayout()
        self.vertLay2.setObjectName("vertLay2")
        self.fileEdit = QtWidgets.QLineEdit(self.widget)
        self.fileEdit.setObjectName("fileEdit")
        self.vertLay2.addWidget(self.fileEdit)
        self.progress = QtWidgets.QProgressBar(self.widget)
        self.progress.setProperty("value", 0)
        self.progress.setObjectName("progress")
        self.vertLay2.addWidget(self.progress)
        self.ContLay.addLayout(self.vertLay2)
        self.vertLay3 = QtWidgets.QVBoxLayout()
        self.vertLay3.setObjectName("vertLay3")
        self.browButt = QtWidgets.QPushButton(self.widget)
        self.browButt.setObjectName("browButt")
        self.vertLay3.addWidget(self.browButt)
        self.successLabel = QtWidgets.QLabel(self.widget)
        self.successLabel.setText("")
        self.successLabel.setObjectName("successLabel")
        self.vertLay3.addWidget(self.successLabel)
        self.ContLay.addLayout(self.vertLay3)
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.ContLay.addItem(spacerItem)
        self.MainLay.addLayout(self.ContLay)

        self.retranslateUi(Main)
        QtCore.QMetaObject.connectSlotsByName(Main)

    def retranslateUi(self, Main):
        _translate = QtCore.QCoreApplication.translate
        Main.setWindowTitle(_translate("Main", "Uploader"))
        self.textEdit.setHtml(_translate("Main", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:\'Ubuntu\'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><br /></p></body></html>"))
        self.connButt.setText(_translate("Main", "Connect"))
        self.sendButt.setText(_translate("Main", "Send"))
        self.browButt.setText(_translate("Main", "Browse"))


# ~ if __name__ == "__main__":
    # ~ import sys
    # ~ app = QtWidgets.QApplication(sys.argv)
    # ~ Main = QtWidgets.QWidget()
    # ~ ui = Ui_Main()
    # ~ ui.setupUi(Main)
    # ~ Main.show()
    # ~ sys.exit(app.exec_())

