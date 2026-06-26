import 'package:flutter/material.dart';

abstract class ReaderEngine {
  Future<void> open();

  Widget buildView();

  void nextPage();
  void prevPage();

  dynamic getProgress();
  void setProgress(dynamic value);

  void dispose();
}