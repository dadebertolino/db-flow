/// Indirizzamento nell'albero: un punto di inserimento in una lista di blocchi.
library;

/// Quale lista di un blocco contenitore.
enum Branch { body, then, otherwise }

/// Posizione [index] nella lista [branch] del blocco [parentId]
/// (`parentId == null` → corpo principale del programma).
final class Slot {
  const Slot(this.parentId, this.branch, this.index);

  const Slot.root(this.index) : parentId = null, branch = Branch.body;

  final String? parentId;
  final Branch branch;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is Slot && other.parentId == parentId && other.branch == branch && other.index == index;

  @override
  int get hashCode => Object.hash(parentId, branch, index);

  @override
  String toString() => 'Slot(${parentId ?? 'root'}.${branch.name}[$index])';
}
