import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/fade_route.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _prenomCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  String? _pays;
  DateTime? _dateNaissance;
  String _countryCode = '+33';
  String _countryFlag = '🇫🇷';
  final Set<String> _animals_selected = {};
  String? _niveau;

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() {}));
  }

  static const _animals = [
    ('🦎', 'Lézard'),
    ('🐍', 'Serpent'),
    ('🕷️', 'Araignée'),
    ('🐢', 'Tortue'),
    ('🐾', 'Autre'),
  ];
  static const _niveaux = ['Débutant', 'Intermédiaire', 'Expert'];

  // (flag, name)
  static const _pays_list = [
    ('🇦🇫','Afghanistan'),('🇿🇦','Afrique du Sud'),('🇦🇱','Albanie'),('🇩🇿','Algérie'),
    ('🇩🇪','Allemagne'),('🇦🇩','Andorre'),('🇦🇴','Angola'),('🇸🇦','Arabie Saoudite'),
    ('🇦🇷','Argentine'),('🇦🇲','Arménie'),('🇦🇺','Australie'),('🇦🇹','Autriche'),
    ('🇦🇿','Azerbaïdjan'),('🇧🇭','Bahreïn'),('🇧🇩','Bangladesh'),('🇧🇪','Belgique'),
    ('🇧🇯','Bénin'),('🇧🇾','Biélorussie'),('🇧🇴','Bolivie'),('🇧🇦','Bosnie-Herzégovine'),
    ('🇧🇷','Brésil'),('🇧🇬','Bulgarie'),('🇧🇫','Burkina Faso'),('🇰🇭','Cambodge'),
    ('🇨🇲','Cameroun'),('🇨🇦','Canada'),('🇨🇱','Chili'),('🇨🇳','Chine'),
    ('🇨🇾','Chypre'),('🇨🇴','Colombie'),('🇨🇬','Congo'),('🇰🇷','Corée du Sud'),
    ('🇨🇷','Costa Rica'),('🇨🇮','Côte d\'Ivoire'),('🇭🇷','Croatie'),('🇨🇺','Cuba'),
    ('🇩🇰','Danemark'),('🇪🇬','Égypte'),('🇦🇪','Émirats arabes unis'),('🇪🇨','Équateur'),
    ('🇪🇸','Espagne'),('🇪🇪','Estonie'),('🇪🇹','Éthiopie'),('🇫🇮','Finlande'),
    ('🇫🇷','France'),('🇬🇦','Gabon'),('🇬🇭','Ghana'),('🇬🇷','Grèce'),
    ('🇬🇹','Guatemala'),('🇭🇹','Haïti'),('🇭🇳','Honduras'),('🇭🇺','Hongrie'),
    ('🇮🇳','Inde'),('🇮🇩','Indonésie'),('🇮🇶','Irak'),('🇮🇷','Iran'),
    ('🇮🇪','Irlande'),('🇮🇸','Islande'),('🇮🇱','Israël'),('🇮🇹','Italie'),
    ('🇯🇲','Jamaïque'),('🇯🇵','Japon'),('🇯🇴','Jordanie'),('🇰🇿','Kazakhstan'),
    ('🇰🇪','Kenya'),('🇽🇰','Kosovo'),('🇰🇼','Koweït'),('🇱🇦','Laos'),
    ('🇱🇻','Lettonie'),('🇱🇧','Liban'),('🇱🇾','Libye'),('🇱🇹','Lituanie'),
    ('🇱🇺','Luxembourg'),('🇲🇰','Macédoine'),('🇲🇬','Madagascar'),('🇲🇾','Malaisie'),
    ('🇲🇱','Mali'),('🇲🇦','Maroc'),('🇲🇺','Maurice'),('🇲🇷','Mauritanie'),
    ('🇲🇽','Mexique'),('🇲🇩','Moldavie'),('🇲🇨','Monaco'),('🇲🇳','Mongolie'),
    ('🇲🇪','Monténégro'),('🇲🇿','Mozambique'),('🇲🇲','Myanmar'),('🇳🇦','Namibie'),
    ('🇳🇵','Népal'),('🇳🇮','Nicaragua'),('🇳🇪','Niger'),('🇳🇬','Nigéria'),
    ('🇳🇴','Norvège'),('🇳🇿','Nouvelle-Zélande'),('🇴🇲','Oman'),('🇺🇬','Ouganda'),
    ('🇺🇿','Ouzbékistan'),('🇵🇰','Pakistan'),('🇵🇸','Palestine'),('🇵🇦','Panama'),
    ('🇵🇾','Paraguay'),('🇳🇱','Pays-Bas'),('🇵🇪','Pérou'),('🇵🇭','Philippines'),
    ('🇵🇱','Pologne'),('🇵🇹','Portugal'),('🇶🇦','Qatar'),('🇩🇴','République dominicaine'),
    ('🇨🇿','République tchèque'),('🇷🇴','Roumanie'),('🇬🇧','Royaume-Uni'),
    ('🇷🇺','Russie'),('🇷🇼','Rwanda'),('🇸🇳','Sénégal'),('🇷🇸','Serbie'),
    ('🇸🇬','Singapour'),('🇸🇰','Slovaquie'),('🇸🇮','Slovénie'),('🇸🇴','Somalie'),
    ('🇸🇩','Soudan'),('🇱🇰','Sri Lanka'),('🇸🇪','Suède'),('🇨🇭','Suisse'),
    ('🇸🇾','Syrie'),('🇹🇼','Taïwan'),('🇹🇿','Tanzanie'),('🇹🇭','Thaïlande'),
    ('🇹🇬','Togo'),('🇹🇳','Tunisie'),('🇹🇷','Turquie'),('🇺🇦','Ukraine'),
    ('🇺🇾','Uruguay'),('🇻🇪','Venezuela'),('🇻🇳','Vietnam'),('🇾🇪','Yémen'),
    ('🇿🇼','Zimbabwe'),
  ];

  // ── Validation ──────────────────────────────────────────────────────────────

  bool _isValidEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  String? _validatePage1() {
    if (_prenomCtrl.text.trim().isEmpty) return 'Le prénom est obligatoire.';
    if (_emailCtrl.text.trim().isEmpty) return 'L\'email est obligatoire.';
    if (!_isValidEmail(_emailCtrl.text)) return 'Adresse email invalide.';
    if (_passCtrl.text.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères.';
    return null;
  }

  void _next() {
    final err = _validatePage1();
    if (err != null) { setState(() => _error = err); return; }
    setState(() => _error = null);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
    setState(() => _page++);
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(_prenomCtrl.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'prenom': _prenomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty) 'phone': '$_countryCode ${_phoneCtrl.text.trim()}',
        if (_pays != null) 'pays': _pays,
        if (_dateNaissance != null) 'dateNaissance': Timestamp.fromDate(_dateNaissance!),
        if (_animals_selected.isNotEmpty) 'animaux': _animals_selected.toList(),
        if (_niveau != null) 'niveau': _niveau,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'Cet email est déjà utilisé.',
          'invalid-email'        => 'Adresse email invalide.',
          'weak-password'        => 'Mot de passe trop faible.',
          _                      => e.message ?? 'Erreur d\'inscription.',
        };
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Une erreur est survenue.'; _loading = false; });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (_page > 0) {
                    _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic);
                    setState(() { _page--; _error = null; });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Retour', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ),
              const Spacer(),
              Text('${_page + 1}/2',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_page + 1) / 2,
                backgroundColor: AppColors.borderLight,
                color: AppColors.accentGreen,
                minHeight: 3,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildPage1(), _buildPage2()],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Page 1 ──────────────────────────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.canopy, shape: BoxShape.circle),
          child: Icon(Icons.eco, color: AppColors.iconGreen, size: 30),
        ),
        const SizedBox(height: 20),
        Text('Créer un compte', style: AppTextStyles.serif32),
        const SizedBox(height: 8),
        Text('Rejoins la communauté Terra',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
        const SizedBox(height: 32),

        _label('Prénom *'),
        const SizedBox(height: 8),
        _Input(hint: 'Ton prénom', icon: Icons.person_outline, controller: _prenomCtrl,
            textCapitalization: TextCapitalization.words),
        const SizedBox(height: 16),

        _label('Email *'),
        const SizedBox(height: 8),
        _Input(hint: 'exemple@email.com', icon: Icons.mail_outline,
            controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),

        _label('Mot de passe * (8 caractères min.)'),
        const SizedBox(height: 8),
        _PasswordInput(controller: _passCtrl, obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure)),
        const SizedBox(height: 4),
        // Indicateur de force
        if (_passCtrl.text.isNotEmpty) _PasswordStrength(password: _passCtrl.text),
        const SizedBox(height: 16),

        _label('Date de naissance'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateNaissance ?? DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
              locale: const Locale('fr'),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppColors.accentGreen,
                    surface: AppColors.card,
                    onSurface: AppColors.textPrimary,
                  ),
                  dialogTheme: DialogThemeData(backgroundColor: AppColors.bg),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _dateNaissance = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Icon(Icons.cake_outlined,
                  color: _dateNaissance != null ? AppColors.accentGreen : AppColors.textMuted,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _dateNaissance != null
                    ? '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'
                    : 'JJ/MM/AAAA',
                style: TextStyle(fontSize: 15,
                    color: _dateNaissance != null ? AppColors.textPrimary : AppColors.textMuted),
              )),
              if (_dateNaissance != null)
                GestureDetector(
                  onTap: () => setState(() => _dateNaissance = null),
                  child: Icon(Icons.close, color: AppColors.textMuted, size: 18),
                )
              else
                Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        _label('Téléphone'),
        const SizedBox(height: 8),
        _PhoneInput(
          controller: _phoneCtrl,
          countryCode: _countryCode,
          countryFlag: _countryFlag,
          onCodeChanged: (code, flag) => setState(() {
            _countryCode = code;
            _countryFlag = flag;
          }),
        ),
        const SizedBox(height: 16),

        _label('Pays'),
        const SizedBox(height: 8),
        _CountryPicker(
          value: _pays,
          onChanged: (v) => setState(() => _pays = v),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 28),
        _PrimaryBtn(label: 'Suivant →', onTap: _next),
        const SizedBox(height: 16),
        Center(child: Text('Les champs * sont obligatoires.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint))),
      ]),
    );
  }

  // ── Page 2 ──────────────────────────────────────────────────────────────────

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ton terrarium', style: AppTextStyles.serif32),
        const SizedBox(height: 8),
        Text('Dis-nous en plus sur toi',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
        const SizedBox(height: 32),

        _label('Quel(s) animal(aux) as-tu ?'),
        const SizedBox(height: 4),
        Text('Plusieurs choix possibles',
            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10,
          children: _animals.map((a) {
            final selected = _animals_selected.contains(a.$2);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _animals_selected.remove(a.$2);
                else _animals_selected.add(a.$2);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected ? AppColors.accentGreen : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (selected) ...[
                    Icon(Icons.check, size: 14, color: AppColors.accentGreen),
                    const SizedBox(width: 6),
                  ],
                  Text(a.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(a.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: selected ? AppColors.accentGreen : AppColors.textSecondary)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _label('Niveau d\'expérience'),
        const SizedBox(height: 12),
        Row(children: _niveaux.map((n) {
          final selected = _niveau == n;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: n != _niveaux.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _niveau = selected ? null : n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.accentGreen : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(children: [
                  Text(_niveauIcon(n), style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(n, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? AppColors.accentGreen : AppColors.textSecondary)),
                ]),
              ),
            ),
          ));
        }).toList()),

        if (_error != null) ...[
          const SizedBox(height: 20),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 32),
        _PrimaryBtn(label: _loading ? '...' : 'Créer mon compte',
            onTap: _loading ? null : _submit, loading: _loading),
      ]),
    );
  }

  String _niveauIcon(String n) => switch (n) {
    'Débutant'      => '🌱',
    'Intermédiaire' => '🌿',
    'Expert'        => '🌳',
    _               => '🌱',
  };

  Widget _label(String t) => Text(t,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.3));

  @override
  void dispose() {
    _pageCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _CountryPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _CountryPicker({required this.value, required this.onChanged});

  static const _countries = _RegisterScreenState._pays_list;

  String? _flagFor(String name) {
    try { return _countries.firstWhere((c) => c.$2 == name).$1; } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final flag = value != null ? _flagFor(value!) : null;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          flag != null
              ? Text(flag, style: const TextStyle(fontSize: 20))
              : Icon(Icons.public_outlined, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            value ?? 'Sélectionner un pays',
            style: TextStyle(fontSize: 15,
                color: value != null ? AppColors.textPrimary : AppColors.textMuted),
          )),
          Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = searchCtrl.text.isEmpty
              ? _countries
              : _countries.where((c) =>
                  c.$2.toLowerCase().contains(searchCtrl.text.toLowerCase())).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(children: [
              Container(width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: TextField(
                    controller: searchCtrl, autofocus: true,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    onChanged: (_) => setS(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays…',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final selected = value == c.$2;
                    return ListTile(
                      leading: Text(c.$1, style: const TextStyle(fontSize: 22)),
                      title: Text(c.$2,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                      trailing: selected
                          ? Icon(Icons.check, color: AppColors.accentGreen, size: 20)
                          : null,
                      onTap: () { onChanged(c.$2); Navigator.pop(ctx); },
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final String countryFlag;
  final void Function(String code, String flag) onCodeChanged;

  const _PhoneInput({
    required this.controller,
    required this.countryCode,
    required this.countryFlag,
    required this.onCodeChanged,
  });

  static const _codes = [
    ('+33',  '🇫🇷', 'France'),
    ('+32',  '🇧🇪', 'Belgique'),
    ('+41',  '🇨🇭', 'Suisse'),
    ('+352', '🇱🇺', 'Luxembourg'),
    ('+1',   '🇺🇸', 'États-Unis'),
    ('+1',   '🇨🇦', 'Canada'),
    ('+44',  '🇬🇧', 'Royaume-Uni'),
    ('+49',  '🇩🇪', 'Allemagne'),
    ('+34',  '🇪🇸', 'Espagne'),
    ('+39',  '🇮🇹', 'Italie'),
    ('+351', '🇵🇹', 'Portugal'),
    ('+31',  '🇳🇱', 'Pays-Bas'),
    ('+212', '🇲🇦', 'Maroc'),
    ('+213', '🇩🇿', 'Algérie'),
    ('+216', '🇹🇳', 'Tunisie'),
    ('+221', '🇸🇳', 'Sénégal'),
    ('+225', '🇨🇮', 'Côte d\'Ivoire'),
    ('+237', '🇨🇲', 'Cameroun'),
    ('+242', '🇨🇬', 'Congo'),
    ('+261', '🇲🇬', 'Madagascar'),
    ('+230', '🇲🇺', 'Maurice'),
    ('+62',  '🇮🇩', 'Indonésie'),
    ('+81',  '🇯🇵', 'Japon'),
    ('+82',  '🇰🇷', 'Corée du Sud'),
    ('+86',  '🇨🇳', 'Chine'),
    ('+91',  '🇮🇳', 'Inde'),
    ('+55',  '🇧🇷', 'Brésil'),
    ('+52',  '🇲🇽', 'Mexique'),
    ('+54',  '🇦🇷', 'Argentine'),
    ('+7',   '🇷🇺', 'Russie'),
    ('+61',  '🇦🇺', 'Australie'),
    ('+64',  '🇳🇿', 'Nouvelle-Zélande'),
    ('+27',  '🇿🇦', 'Afrique du Sud'),
  ];

  void _showPicker(BuildContext context) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = searchCtrl.text.isEmpty
              ? _codes
              : _codes.where((c) =>
                  c.$3.toLowerCase().contains(searchCtrl.text.toLowerCase()) ||
                  c.$1.contains(searchCtrl.text)).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Column(children: [
              Container(width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    onChanged: (_) => setS(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays…',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final selected = c.$1 == countryCode && c.$2 == countryFlag;
                    return ListTile(
                      leading: Text(c.$2, style: const TextStyle(fontSize: 22)),
                      title: Text(c.$3,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c.$1, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check, color: AppColors.accentGreen, size: 18),
                        ],
                      ]),
                      onTap: () {
                        onCodeChanged(c.$1, c.$2);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(countryFlag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(countryCode,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
            ]),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 15,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '6 00 00 00 00',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  // Score 1-4 basé sur longueur + complexité
  int get _score {
    final len = password.length;
    int s = 0;
    if (len >= 1) s = 1;           // commence à 1 dès le premier caractère
    if (len >= 8) s = 2;           // moyen à 8 car
    if (len >= 12 || (len >= 8 &&  // fort si long OU 8+ avec complexité
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password))) s = 3;
    if (len >= 16 ||               // très fort si très long OU complexe
        (len >= 10 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*]').hasMatch(password))) s = 4;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _score;
    final (color, label) = switch (s) {
      1 => (AppColors.red,               'Faible'),
      2 => (const Color(0xFFE8A040),     'Moyen'),
      3 => (AppColors.accentGreen,       'Fort'),
      _ => (const Color(0xFF2ECC71),     'Très fort'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(children: [
        ...List.generate(4, (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 4,
              decoration: BoxDecoration(
                color: i < s ? color : AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        )),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(label,
            key: ValueKey(label),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _Input extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  const _Input({
    required this.hint, required this.icon, required this.controller,
    this.keyboardType, this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordInput({required this.controller, required this.obscure, required this.onToggle});
  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscure,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Minimum 8 caractères',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
          suffixIcon: GestureDetector(
            onTap: widget.onToggle,
            child: Icon(widget.obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryBtn({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.accentGreen.withValues(alpha: 0.5)
              : AppColors.accentGreen,
          borderRadius: BorderRadius.circular(50),
          boxShadow: onTap != null ? [
            BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.3),
                blurRadius: 20, offset: const Offset(0, 6)),
          ] : null,
        ),
        child: loading
            ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.red, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: const TextStyle(fontSize: 13, color: AppColors.red))),
    ]),
  );
}
