import 'package:flutter/material.dart';

const categoriasEquipo = {
  1: 'Educación',
  2: 'Finanzas',
  3: 'Salud',
  4: 'Disciplina',
};

class FormularioTareaEquipo extends StatefulWidget {
  const FormularioTareaEquipo({super.key, required this.miembros});
  final List<dynamic> miembros;
  @override
  State<FormularioTareaEquipo> createState() => _FormularioTareaEquipoState();
}

class _FormularioTareaEquipoState extends State<FormularioTareaEquipo> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _categorias = <int>{4};
  final _asignados = <int>{};
  String _prioridad = 'Media';
  DateTime? _fecha;
  String? _error;
  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Asignar tarea'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titulo,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (s) =>
                  s == null || s.trim().isEmpty ? 'Escribe un título' : null,
            ),
            TextFormField(
              controller: _descripcion,
              maxLength: 2000,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _prioridad,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: [
                'Baja',
                'Media',
                'Alta',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => _prioridad = s!),
            ),
            const SizedBox(height: 16),
            const Text('Categorías'),
            Wrap(
              spacing: 6,
              children: categoriasEquipo.entries
                  .map(
                    (e) => FilterChip(
                      label: Text(e.value),
                      selected: _categorias.contains(e.key),
                      onSelected: (v) => setState(() {
                        v ? _categorias.add(e.key) : _categorias.remove(e.key);
                      }),
                    ),
                  )
                  .toList(),
            ),
            TextButton.icon(
              icon: const Icon(Icons.event),
              label: Text(
                _fecha == null
                    ? 'Sin fecha límite'
                    : 'Fecha: ${_fecha!.day}/${_fecha!.month}/${_fecha!.year}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fecha ?? now,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 10),
                );
                if (mounted && date != null) setState(() => _fecha = date);
              },
            ),
            if (_fecha != null)
              TextButton(
                onPressed: () => setState(() => _fecha = null),
                child: const Text('Quitar fecha'),
              ),
            const Text('Participantes · todos deben marcar su parte'),
            ...widget.miembros.map(
              (m) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('@${m['nickName']}'),
                value: _asignados.contains(m['idUsu']),
                onChanged: (v) => setState(() {
                  v!
                      ? _asignados.add(m['idUsu'] as int)
                      : _asignados.remove(m['idUsu']);
                }),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          if (_categorias.isEmpty || _asignados.isEmpty) {
            setState(
              () => _error =
                  'Selecciona una categoría y al menos un participante.',
            );
            return;
          }
          Navigator.pop(context, <String, dynamic>{
            'titulo': _titulo.text.trim(),
            'descripcion': _descripcion.text.trim(),
            'prioridad': _prioridad,
            'categorias': _categorias.toList(),
            'participantes': _asignados.toList(),
            'fechaLimite': _fecha?.toIso8601String().split('T').first,
          });
        },
        child: const Text('Asignar'),
      ),
    ],
  );
}
