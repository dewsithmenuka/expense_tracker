import 'package:flutter/material.dart';

/// Attached to MaterialApp so code outside widgets can control navigation.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();