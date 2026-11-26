# AndénLibre

**Unha aplicación  para consultar as circulacións de ADIF e gardar billetes nun só lugar.**

[Read this page in English](README.en.md)

AndénLibre é unha APP Flutter para iOS, Android e Web. Permite importar billetes, consultar saídas e chegadas ferroviarias en tempo real cando o servizo está dispoñible, e acceder á información da viaxe desde widgets ou actividades en directo compatibles.

> **Estado do proxecto:** en desenvolvemento. A dispoñibilidade e a precisión dos datos dependen de varios servizos externos. Comproba sempre a información nos paneis oficiais da estación e no billete orixinal. Non me fago responsable de ningún problema derivado do emprego da app a estas alturas.

## Funcionalidades

- **Billeteira local:** garda e organiza billetes no dispositivo.
- **Importación de billetes:**
  - Ficheiros Apple Wallet `.pkpass`.
  - Billetes PDF, con OCR/texto para os formatos de billete Renfe recoñecidos.
  - Entrada manual.
  - Apertura ou recepción de ficheiros compartidos nas plataformas compatibles.
- **Lectura do billete:** extracción de datos como orixe, destino, horarios, tren, coche, asento, localizador e código de barras cando están dispoñibles no documento.
- **Tempo real:** consulta de saídas e chegadas por estación a través da función de Supabase incluída no repositorio.
- **Widgets e seguimento da viaxe:** widget de saídas para iOS e Android; Live Activity de iOS e notificación de viaxe en curso en Android.
- **Google Wallet en Android:** importación experimental de ligazóns Save to Google Wallet con datos que o conversor poida recoñecer.
- **Deseño adaptado ás plataformas:** interface en galego, identidade ADIF e superficies Liquid Glass en iOS.

AndénLibre non incorpora billetes nin horarios ficticios. Se unha estación non ofrece datos ou o servizo non responde, a aplicación non pode garantir que haxa información dispoñible.

## Compatibilidade e requisitos

- Flutter e Dart compatibles coas versións indicadas en [`pubspec.yaml`](pubspec.yaml).
- **iOS:** destino mínimo iOS 18; Xcode para compilar e asinar a aplicación.
- **Android:** Android SDK 36 e Java 17 para a configuración actual de Gradle.
- Conexión á rede para consultar os paneis en tempo real.
- Un proxecto de Supabase propio ou accesible para despregar a función de paneis.

As Live Activities requiren un dispositivo iOS compatible e as opcións correspondentes activadas no sistema. As notificacións persistentes de Android poden requirir permiso de notificacións segundo a versión do sistema.

## Comezar

Este repositorio usa Git LFS para certos ficheiros grandes. Instálao antes de clonar para descargar os contidos correctamente:

```sh
git lfs install
git clone https://github.com/wtfroichi/ADIF-Connect.git
cd ADIF-Connect
git lfs pull
flutter pub get
```

Inicia a aplicación:

```sh
flutter run
```

### Executar comprobacións

```sh
flutter analyze
flutter test
```

### Compilar

```sh
# Android
flutter build apk --release
flutter build appbundle --release

# iOS; require Xcode e configuración de sinatura para unha distribución real
flutter build ios --release
```

Para comprobar unha compilación iOS sen asinar:

```sh
flutter build ios --no-codesign
```

## Paneis en tempo real con Supabase

A función Edge `adif-board` consulta fontes externas de circulacións e mantén unha caché de paneis. A caché persistente usa a migración de base de datos incluída; a función tamén aplica unha caché en memoria de curta duración. As fontes externas e o seu formato poden cambiar sen aviso.

1. Instala e autentícate co [CLI de Supabase](https://supabase.com/docs/guides/cli).
2. Enlaza o proxecto e aplica a migración:

   ```sh
   supabase login
   supabase link --project-ref O_TE_PROXECTO
   supabase db push
   ```

3. Desprega a función:

   ```sh
   supabase functions deploy adif-board
   ```

4. Configura o URL do proxecto e a chave pública de cliente ao executar ou compilar Flutter:

   ```sh
   flutter run \
     --dart-define=SUPABASE_URL=https://O_TE_PROXECTO.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=A_TUA_CHAVE_PUBLICA
   ```

   Para unha compilación, engade os mesmos `--dart-define` ao comando `flutter build`.

Non inclúas chaves `service_role` nin outros segredos no cliente móbil, no repositorio ou nos argumentos distribuídos coa aplicación. A chave de cliente non substitúe as políticas de acceso do lado servidor.

## Importación e limitacións coñecidas

- **PDF:** o analizador recoñece campos e abreviacións habituais dos billetes Renfe. En Android usa extracción de texto do PDF; os documentos escaneados como imaxe poden non ser interpretables. En iOS existe unha vía de OCR para documentos dos que non se pode extraer texto suficiente.
- **Códigos de barras:** créanse cando o billete inclúe un número ou contido que a aplicación pode identificar. Non se inventa un código se falta esa información.
- **Google Wallet:** a compatibilidade é experimental. A aplicación interpreta certos campos dun JWT e só crea un billete cando pode resolver as estacións e os horarios; non verifica a sinatura do JWT nin garante compatibilidade con todos os tipos de obxecto.
- **Circulacións:** a función depende de fontes externas non controladas por este proxecto. Pode haber estacións sen datos, atrasos na actualización ou cambios no servizo.
- **Información mostrada:** unha vía non se estima; cando non está indicada, aparece como pendente ou non asignada.

## Estrutura do proxecto

```text
lib/
  core/                 Constantes, tema e compoñentes compartidos
  features/             Inicio, billeteira, tempo real e axustes
  models/               Modelos de billete e circulación
  services/             Importación, almacenamento e integracións
ios/
  Runner/               Aplicación iOS e integracións nativas
  TrainLiveActivity/    Widget de saídas e Live Activity
  ShareExtension/       Recepción de contido compartido
android/
  app/                  Aplicación, widget e integracións nativas Android
supabase/
  functions/adif-board/ Función Edge dos paneis ferroviarios
  migrations/           Esquema da caché de paneis
```

## Privacidade e datos

Os billetes gardados persístense localmente no dispositivo mediante almacenamento de preferencias. A consulta de paneis envía o código da estación á función de Supabase; os datos do billete non forman parte desa consulta. As integracións do sistema operativo poden compartir os datos necesarios coa extensión ou widget local para amosar a viaxe.

Consulta as políticas e condicións dos servizos externos antes de usar a aplicación con información sensible.

## Contribuír

As contribucións son benvidas. Para cambios de código:

1. Mantén en galego normativo todas as cadeas visibles para a persoa usuaria.
2. Non engadas billetes nin horarios ficticios.
3. Executa `flutter analyze` e `flutter test` antes de abrir unha solicitude de cambio.
4. Non subas credenciais nin ficheiros privados.

---

AndénLibre é un proxecto independente e non implica afiliación nin respaldo de ADIF, Renfe, Apple, Google ou Supabase. Asimesmo, trátase dun proxecto aberto e sen ánimo de lucro. Se calquera marca implicada quixer ser removida deste proxecto a modo de imaxe, fágaseme saber en dev@rprieto.com.
