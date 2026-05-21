import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../domain/entities/transaction.dart';
import 'transaction_list_item.dart';

class SwipeDeleteItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const SwipeDeleteItem({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  State<SwipeDeleteItem> createState() => _SwipeDeleteItemState();
}

class _SwipeDeleteItemState extends State<SwipeDeleteItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset < -100) {
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 200, damping: 20),
        _dragOffset, -400, details.velocity.pixelsPerSecond.dx / 400,
      );
      _controller.animateWith(simulation).then((_) => widget.onDelete());
    } else {
      final simulation = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 500, damping: 25),
        _dragOffset, 0, 0,
      );
      _controller
          .animateWith(simulation)
          .then((_) => setState(() => _dragOffset = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Material(
              type: MaterialType.canvas,
              elevation: 1,
              child: TransactionListItem(transaction: widget.transaction),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
