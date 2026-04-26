// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Farha';

  @override
  String get tagline => 'L\'Atelier Numérique';

  @override
  String get login => 'Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get continueGuest => 'Continuer en tant qu\'invité';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ?';

  @override
  String get dontHaveAccount => 'Pas encore de compte ?';

  @override
  String get email => 'Adresse email';

  @override
  String get phone => 'Numéro de téléphone';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get sendResetCode => 'Envoyer le code';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get verifyEmailTitle => 'Vérifiez votre email';

  @override
  String verifyEmailBody(String email) {
    return 'Nous avons envoyé un lien de vérification à $email. Cliquez dessus pour vérifier votre compte.';
  }

  @override
  String get createCustomerAccount => 'Créer un compte client';

  @override
  String get createTailorAccount => 'Créer un compte tailleur';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get gender => 'Genre';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get other => 'Autre';

  @override
  String get preferNotToSay => 'Préfère ne pas dire';

  @override
  String get preferredLanguage => 'Langue préférée';

  @override
  String get shopName => 'Nom de la boutique';

  @override
  String get shopLocation => 'Emplacement de la boutique';

  @override
  String get yearsExperience => 'Années d\'expérience';

  @override
  String get aboutWork => 'À propos de votre travail (optionnel)';

  @override
  String get termsAgreement =>
      'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInDetails =>
      'Veuillez saisir vos informations pour vous connecter';

  @override
  String get emailOrPhone => 'Email ou téléphone';

  @override
  String get iAm => 'Je suis...';

  @override
  String get chooseAccountType =>
      'Choisissez le type de compte qui correspond à votre parcours.';

  @override
  String get customer => 'Client';

  @override
  String get customerSubtitle => 'Je veux commander des vêtements';

  @override
  String get tailor => 'Tailleur';

  @override
  String get tailorSubtitle => 'Je veux vendre mon travail';

  @override
  String get home => 'Accueil';

  @override
  String get shop => 'Boutique';

  @override
  String get orders => 'Commandes';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profil';

  @override
  String get products => 'Produits';

  @override
  String get clients => 'Clients';

  @override
  String get revenue => 'Revenus';

  @override
  String get ourCollection => 'Notre Collection';

  @override
  String get readyMade => 'Prêt-à-porter';

  @override
  String get customMade => 'Sur mesure';

  @override
  String get shopNow => 'Acheter maintenant';

  @override
  String get orderNow => 'Commander maintenant';

  @override
  String get allCategories => 'Tout';

  @override
  String get filterProducts => 'Filtrer';

  @override
  String get sortProducts => 'Trier';

  @override
  String get addToCart => 'Ajouter au panier';

  @override
  String get addToWishlist => 'Ajouter aux favoris';

  @override
  String get selectSize => 'Choisir la taille';

  @override
  String get sizeGuide => 'Guide des tailles';

  @override
  String get quantity => 'Quantité';

  @override
  String get description => 'Description';

  @override
  String get craftedBy => 'Créé par';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get messageTailor => 'Contacter le tailleur';

  @override
  String get reviews => 'Avis';

  @override
  String get allReviews => 'Tous les avis';

  @override
  String get verifiedBuyer => 'Acheteur vérifié';

  @override
  String get orderHistory => 'Historique des commandes';

  @override
  String get trackOrder => 'Suivre la commande';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get cancelOrder => 'Annuler la commande';

  @override
  String get payBalance => 'Payer le solde restant';

  @override
  String get inProgress => 'En cours';

  @override
  String get completed => 'Terminé';

  @override
  String get cancelled => 'Annulé';

  @override
  String get refundProcessed => 'Remboursement traité';

  @override
  String get createCustomOrder => 'Créer une commande sur mesure';

  @override
  String get chooseTailor => 'Choisir un tailleur';

  @override
  String get orderReview => 'Récapitulatif';

  @override
  String get placeOrder => 'Passer la commande';

  @override
  String get orderSuccess => 'Commande passée avec succès !';

  @override
  String get orderSuccessBody =>
      'Votre célébration de l\'artisanat a commencé.';

  @override
  String get payment => 'Paiement';

  @override
  String get totalInvoice => 'Montant total';

  @override
  String get depositPlan => 'Acompte (50%)';

  @override
  String get fullAmount => 'Montant total';

  @override
  String get payNow => 'Payer maintenant';

  @override
  String get securePayment => 'Paiement sécurisé';

  @override
  String get paymentMethod => 'Modes de paiement';

  @override
  String get measurements => 'Mesures';

  @override
  String get savedMeasurements => 'Mesures enregistrées';

  @override
  String get addProfile => 'Ajouter un profil';

  @override
  String get useForOrder => 'Utiliser pour une commande';

  @override
  String get chest => 'Tour de poitrine';

  @override
  String get waist => 'Tour de taille';

  @override
  String get hips => 'Tour de hanches';

  @override
  String get shoulder => 'Largeur d\'épaules';

  @override
  String get sleeve => 'Longueur des manches';

  @override
  String get totalLength => 'Longueur totale';

  @override
  String get unit_cm => 'cm';

  @override
  String get unit_inches => 'pouces';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get helpSupport => 'Aide et support';

  @override
  String get language => 'Langue';

  @override
  String get notifications => 'Notifications';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get sharePortfolio => 'Partager le portfolio';

  @override
  String get listNewGarment => 'Lister un nouveau vêtement';

  @override
  String get productName => 'Nom du produit';

  @override
  String get category => 'Catégorie';

  @override
  String get basePrice => 'Prix de base';

  @override
  String get stockQuantity => 'Quantité en stock';

  @override
  String get allowCustom => 'Personnalisation disponible';

  @override
  String get availableForSale => 'Disponible à la vente';

  @override
  String get addPhotos => 'Ajouter des photos';

  @override
  String get totalRevenue => 'Revenu total';

  @override
  String get pendingBalances => 'Soldes en attente';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get thisYear => 'Cette année';

  @override
  String get requestPayout => 'Demander un virement';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get sort => 'Trier';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement...';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get noInternet => 'Pas de connexion internet';

  @override
  String get somethingWrong => 'Une erreur est survenue';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get logoutConfirmTitle => 'Se déconnecter';

  @override
  String get logoutConfirmBody =>
      'Êtes-vous sûr de vouloir vous déconnecter de Farha ?';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get activeOrders => 'Commandes en cours';

  @override
  String get noActiveOrders => 'Aucune commande en cours';

  @override
  String get ordersAppearHere => 'Vos commandes apparaîtront ici';

  @override
  String get featuredTailors => 'Tailleurs en vedette';

  @override
  String get recentOrders => 'Commandes récentes';

  @override
  String get noOrdersYet => 'Aucune commande pour l\'instant';

  @override
  String get trackOrderArrow => 'Suivre la commande →';

  @override
  String completePercent(int percent) {
    return '$percent% complété';
  }

  @override
  String get stagePending => 'En attente';

  @override
  String get stageCutting => 'Découpe';

  @override
  String get stageSewing => 'Couture';

  @override
  String get stageReady => 'Prêt';

  @override
  String get stageDelivered => 'Livré';

  @override
  String get stageConfirmed => 'Confirmé';

  @override
  String get stageCancelled => 'Annulé';

  @override
  String get todaysRevenue => 'Revenu du jour';

  @override
  String get digitalAtelierBuzzing => 'L\'Atelier Numérique est animé.';

  @override
  String get onboardingTitle1 => 'L\'Atelier Numérique';

  @override
  String get onboardingSubtitle1 =>
      'Reliant les Tailleurs et les Clients avec Joie. Créer avec passion.';

  @override
  String get onboardingTitle2 => 'Mesures Parfaites';

  @override
  String get onboardingSubtitle2 =>
      'Enregistrez vos mesures une fois, utilisez-les pour chaque commande sur mesure.';

  @override
  String get onboardingTitle3 => 'Suivez Chaque Point';

  @override
  String get onboardingSubtitle3 =>
      'Regardez votre vêtement prendre vie — de la coupe à la livraison.';

  @override
  String get orContinueWith => 'Ou continuer avec';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get googleSignInComingSoon => 'Connexion Google bientôt disponible.';

  @override
  String get emailOrPhoneHint => 'nom@exemple.com ou +1234567890';

  @override
  String get signInToContinue => 'Connectez-vous pour accéder à votre compte';

  @override
  String get emailPhoneRequired => 'Email ou numéro de téléphone requis';

  @override
  String get invalidEmail =>
      'Veuillez saisir une adresse email valide (ex. nom@exemple.com)';

  @override
  String get invalidPhone =>
      'Saisissez un email valide (nom@domaine.com) ou un téléphone (+1234567890)';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get passwordNeedsUppercase =>
      'Le mot de passe doit contenir au moins une lettre majuscule';

  @override
  String get passwordNeedsLowercase =>
      'Le mot de passe doit contenir au moins une lettre minuscule';

  @override
  String get passwordNeedsNumber =>
      'Le mot de passe doit contenir au moins un chiffre';

  @override
  String get passwordNeedsSpecial =>
      'Le mot de passe doit contenir au moins un caractère spécial (!@#\$...)';

  @override
  String get emailNotVerified =>
      'Votre email n\'est pas vérifié. Veuillez vérifier votre boîte de réception.';

  @override
  String get connectionError =>
      'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';

  @override
  String get attemptsExceeded =>
      'Vous avez dépassé 3 tentatives de connexion. Redirection...';

  @override
  String get wrongCredentials1 =>
      'Email ou mot de passe incorrect. Il vous reste 1 tentative.';

  @override
  String wrongCredentialsN(int remaining) {
    return 'Email ou mot de passe incorrect. Il vous reste $remaining tentatives.';
  }

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String balanceDue(String amount) {
    return 'Solde : $amount';
  }

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get permissionRequired => 'Permission requise';

  @override
  String get permissionCameraBody =>
      'L\'accès à la caméra est nécessaire pour prendre une photo de profil. Veuillez accorder la permission dans les Paramètres.';

  @override
  String get permissionGalleryBody =>
      'L\'accès à la galerie est nécessaire pour choisir une photo de profil. Veuillez accorder la permission dans les Paramètres.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get photoUpdated => 'Photo de profil mise à jour';

  @override
  String get photoFailed => 'Échec de la mise à jour de la photo';

  @override
  String get experienceLevel => 'Niveau d\'expérience';

  @override
  String get rating => 'Note';

  @override
  String get verified => 'Vérifié';

  @override
  String get notVerified => 'Non vérifié';

  @override
  String get accountInfo => 'Informations du compte';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get notificationsEnabled => 'Notifications activées';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get appearance => 'Apparence';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';
}
