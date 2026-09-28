import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/firebase_sync_service.dart';
import '../../core/services/local_store.dart';

class UserAccount {
  final String id;
  final String email;
  final String role;
  String passwordHash;
  Map<String,dynamic> profile;
  UserAccount({required this.id,required this.email,required this.role,required this.passwordHash,required this.profile});
  factory UserAccount.fromMap(Map<String,dynamic> map)=>UserAccount(id:map['id'] as String? ?? '',email:map['email'] as String? ?? '',role:map['role'] as String? ?? UserRole.user,passwordHash:map['passwordHash'] as String? ?? '',profile:(map['profile'] as Map?)?.cast<String,dynamic>() ?? {});
  Map<String,dynamic> toMap()=>{'id':id,'email':email,'role':role,'passwordHash':passwordHash,'profile':profile};
}

class AuthRepository {
  AuthRepository._();
  static final instance=AuthRepository._();
  final LocalStore _store=LocalStore.instance;
  final Random _random=Random();
  UserAccount? _current;
  UserAccount? get currentAccount=>_current;
  String get _newId=>'acc_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  String _hash(String p)=>base64.encode(utf8.encode('vita::${p.trim()}'));
  String hashForDemo(String p)=>_hash(p);
  List<UserAccount> allAccounts()=>_store.readList(StoreKeys.accounts).map(UserAccount.fromMap).toList();
  List<UserAccount> _loadAccounts()=>allAccounts();
  Future<void> saveAccounts(List<UserAccount> a)=>_store.writeList(StoreKeys.accounts,a.map((x)=>x.toMap()).toList(),syncFirebase:false);

  Future<void> seedDemoAccounts() async {
    if (FirebaseBootstrap.ready || _loadAccounts().isNotEmpty) return;
    final now=DateTime.now().toIso8601String();
    final userId='acc_demo_user';
    final nutritionistId='acc_demo_nutritionist';
    final adminId='acc_demo_admin';
    final accounts=[
      UserAccount(id:userId,email:'user@vitatrack.app',role:UserRole.user,passwordHash:_hash('demo1234'),profile:{'id':userId,'email':'user@vitatrack.app','role':'user','fullName':'Afiwa Mbarga','gender':'female','birthDate':'1998-05-12T00:00:00.000','heightCm':165,'activityFactor':1.375,'goalType':'lose','targetWeightKg':62,'calorieGoal':1650,'isOnboarded':true,'emailVerified':true,'favoriteFoodIds':['food_001','food_015'],'createdAt':now}),
      UserAccount(id:nutritionistId,email:'nutritionist@vitatrack.app',role:UserRole.nutritionist,passwordHash:_hash('demo1234'),profile:{'id':nutritionistId,'email':'nutritionist@vitatrack.app','role':'nutritionist','fullName':'Dr. Renaud Adjovi','specialization':'Nutrition générale','licenseNumber':'NUT-DEMO-001','bio':'Nutritionniste VitaTrack','city':'Yaoundé','experienceYears':8,'patientIds':[userId],'isVerified':true,'verificationStatus':'verified','createdAt':now}),
      UserAccount(id:adminId,email:'admin@vitatrack.app',role:UserRole.admin,passwordHash:_hash('demo1234'),profile:{'id':adminId,'email':'admin@vitatrack.app','role':'super_admin','fullName':'Administrateur VitaTrack','createdAt':now}),
    ];
    await saveAccounts(accounts);
  }

  Future<UserAccount?> restoreSession() async {
    if(FirebaseBootstrap.ready){
      final u=FirebaseAuth.instance.currentUser;
      if(u!=null){final a=await _fromFirebase(u);_current=a;await _cache(a);return a;}
    }
    final id=_store.readString(StoreKeys.session); if(id==null)return null;
    final a=_loadAccounts().where((x)=>x.id==id).cast<UserAccount?>().firstOrNull;
    _current=a; return a;
  }

  Future<UserAccount> register({required String email,required String password,required String fullName,required Map<String,dynamic> profile,String role=UserRole.user}) async {
    final normalized=email.trim().toLowerCase();
    if(FirebaseBootstrap.ready){
      try{
        final cred=await FirebaseAuth.instance.createUserWithEmailAndPassword(email:normalized,password:password);
        await cred.user?.updateDisplayName(fullName.trim());
        try { await cred.user?.sendEmailVerification(); } catch (_) {}
        final id=cred.user!.uid;
        final p=Map<String,dynamic>.from(profile)..addAll({'id':id,'email':normalized,'role':role,'fullName':fullName.trim(),'isActive':true,'createdAt':DateTime.now().toIso8601String(),'updatedAt':DateTime.now().toIso8601String()});
        await FirebaseFirestore.instance.collection('users').doc(id).set(p,SetOptions(merge:true));
        final a=UserAccount(id:id,email:normalized,role:role,passwordHash:'',profile:p);_current=a;await _cache(a);await _store.writeString(StoreKeys.session,id);return a;
      }on FirebaseAuthException catch(e){throw AuthException(_message(e.code),code:e.code);}
    }
    if(_loadAccounts().any((a)=>a.email==normalized))throw const AuthException('Un compte existe déjà avec cet email.',code:'email-already-in-use');
    final id=_newId;final a=UserAccount(id:id,email:normalized,role:role,passwordHash:_hash(password),profile:{...profile,'id':id,'email':normalized,'role':role,'fullName':fullName.trim()});
    final list=_loadAccounts()..add(a);await saveAccounts(list);_current=a;await _store.writeString(StoreKeys.session,id);return a;
  }

  Future<UserAccount> login(String email,String password) async {
    final normalized=email.trim().toLowerCase();
    if(FirebaseBootstrap.ready){
      try{final cred=await FirebaseAuth.instance.signInWithEmailAndPassword(email:normalized,password:password);final a=await _fromFirebase(cred.user!);_current=a;await _cache(a);await _store.writeString(StoreKeys.session,a.id);await FirebaseSyncService.instance.pullForCurrentAccount(role:a.role);return a;}
      on FirebaseAuthException catch(e){throw AuthException(_message(e.code),code:e.code);}
    }
    final a=_loadAccounts().where((x)=>x.email==normalized).cast<UserAccount?>().firstOrNull;
    if(a==null||a.passwordHash!=_hash(password))throw const AuthException('Email ou mot de passe incorrect.',code:'invalid-credential');
    _current=a;await _store.writeString(StoreKeys.session,a.id);return a;
  }

  Future<void> logout() async {if(FirebaseBootstrap.ready){try{await FirebaseAuth.instance.signOut();}catch(_){}}_current=null;await _store.remove(StoreKeys.session);}

  Future<void> updateProfile(UserAccount a) async {
    if(FirebaseBootstrap.ready&&FirebaseAuth.instance.currentUser?.uid==a.id){await FirebaseFirestore.instance.collection('users').doc(a.id).set({...a.profile,'id':a.id,'email':a.email,'role':a.role,'updatedAt':DateTime.now().toIso8601String()},SetOptions(merge:true));}
    final list=_loadAccounts();final i=list.indexWhere((x)=>x.id==a.id);if(i==-1)list.add(a);else list[i]=a;await saveAccounts(list);if(_current?.id==a.id)_current=a;
  }

  Future<void> sendPasswordReset(String email) async {if(FirebaseBootstrap.ready){try{await FirebaseAuth.instance.sendPasswordResetEmail(email:email.trim().toLowerCase());return;}on FirebaseAuthException catch(e){throw AuthException(_message(e.code),code:e.code);}}if(!_loadAccounts().any((a)=>a.email==email.trim().toLowerCase()))throw const AuthException('Aucun compte trouvé avec cet email.',code:'user-not-found');}
  bool checkCurrentPassword(String password) { final a=_current; return a != null && (a.passwordHash.isEmpty || a.passwordHash == _hash(password)); }
  Future<void> changePassword(String id,String fresh) async {if(FirebaseBootstrap.ready&&FirebaseAuth.instance.currentUser?.uid==id){await FirebaseAuth.instance.currentUser!.updatePassword(fresh);return;}final list=_loadAccounts();final i=list.indexWhere((a)=>a.id==id);if(i==-1)throw const NotFoundException('Compte introuvable.');list[i].passwordHash=_hash(fresh);await saveAccounts(list);}
  Future<void> changePasswordWithReauth(String current, String fresh) async {
    if (FirebaseBootstrap.ready) {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null || u.email == null) throw const AuthException('Session expirée.');
      try {
        final cred = EmailAuthProvider.credential(email: u.email!, password: current);
        await u.reauthenticateWithCredential(cred);
        await u.updatePassword(fresh);
        return;
      } on FirebaseAuthException catch (e) {
        throw AuthException(_message(e.code), code: e.code);
      }
    }
    final a = _current;
    if (a == null || a.passwordHash != _hash(current)) throw const AuthException('Mot de passe actuel incorrect.');
    final list = _loadAccounts();
    final i = list.indexWhere((x) => x.id == a.id);
    if (i == -1) throw const NotFoundException('Compte introuvable.');
    list[i].passwordHash = _hash(fresh);
    await saveAccounts(list);
  }
  Future<void> changePasswordOnBackend(String current,String fresh) async => changePasswordWithReauth(current, fresh);
  Future<void> deleteAccount(String id) async {final list=_loadAccounts()..removeWhere((a)=>a.id==id);await saveAccounts(list);if(FirebaseBootstrap.ready&&FirebaseAuth.instance.currentUser?.uid==id)await FirebaseAuth.instance.currentUser!.delete();}
  Future<void> _cache(UserAccount a) async {final list=_loadAccounts();final i=list.indexWhere((x)=>x.id==a.id);if(i==-1)list.add(a);else list[i]=a;await saveAccounts(list);}

  Future<UserAccount> _fromFirebase(User u) async {final snap=await FirebaseFirestore.instance.collection('users').doc(u.uid).get();final p=<String,dynamic>{'id':u.uid,'email':u.email??'','fullName':u.displayName??'','role':UserRole.user,'emailVerified':u.emailVerified,'createdAt':DateTime.now().toIso8601String()};if(snap.exists)p.addAll(snap.data()!);p['id']=u.uid;p['email']=u.email??p['email'];p['emailVerified']=u.emailVerified;final role=p['role']?.toString()??UserRole.user;return UserAccount(id:u.uid,email:u.email??'',role:role,passwordHash:'',profile:p);}
  String _message(String code)=>switch(code){'invalid-credential'=>'Email ou mot de passe incorrect.','invalid-email'=>'Adresse email invalide.','user-not-found'=>'Aucun compte trouvé avec cet email.','wrong-password'=>'Email ou mot de passe incorrect.','email-already-in-use'=>'Un compte existe déjà avec cet email.','weak-password'=>'Le mot de passe doit contenir au moins 6 caractères.','network-request-failed'=>'Connexion réseau indisponible.',_=>'Une erreur Firebase est survenue : $code'};
}
extension<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
