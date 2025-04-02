import 'dart:io';
import 'package:native_assets_cli/code_assets.dart';

LinkMode getLinkMode(LinkModePreference preference) {
  if (preference == LinkModePreference.dynamic ||
      preference == LinkModePreference.preferDynamic) {
    return DynamicLoadingBundled();
  }
  assert(
    preference == LinkModePreference.static ||
        preference == LinkModePreference.preferStatic,
  );
  return StaticLinking();
}

String getArch(String arch) {
  const Map<String, String> archMappings = {
    // x86 / 32-bit Intel
    'i386': 'x86',
    'i486': 'x86',
    'i586': 'x86',
    'i686': 'x86',
    'x86': 'x86',
    'ia32': 'x86',
    
    // x86_64 / 64-bit Intel/AMD
    'x86_64': 'amd64',
    'amd64': 'amd64',
    'x64': 'amd64',
    'intel64': 'amd64',
    
    // ARM 32-bit
    'arm': 'arm',
    'armv6': 'arm',
    'armv7': 'arm',
    'armv7l': 'arm',
    'arm32': 'arm',
    'armhf': 'arm',
    'armel': 'arm',
    
    // ARM 64-bit
    'arm64': 'arm64',
    'aarch64': 'arm64',
    'armv8': 'arm64',
    'arm64e': 'arm64',
    'arm64ec': 'arm64',
    
    // MIPS
    'mips': 'mips',
    'mipsel': 'mips',
    'mips64': 'mips64',
    'mips64el': 'mips64',
    
    // PowerPC
    'ppc': 'ppc',
    'powerpc': 'ppc',
    'ppc64': 'ppc64',
    'powerpc64': 'ppc64',
    'ppc64le': 'ppc64le',
    'powerpc64le': 'ppc64le',
    
    // RISC-V
    'riscv': 'riscv',
    'riscv32': 'riscv32',
    'riscv64': 'riscv64',
    
    // IBM System z
    's390': 's390',
    's390x': 's390x',
  };
  
  return archMappings[arch.toLowerCase()] ?? arch;
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    final os = input.config.code.targetOS;
    final arch = getArch(input.config.code.targetArchitecture.name);
    final linkMode = getLinkMode(input.config.code.linkModePreference);
    
    final libraryFileName = os.libraryFileName(input.packageName, linkMode);
    final libUri = input.outputDirectory.resolve(libraryFileName);
    
    final prebuiltPath = 'native/$os/$arch/$libraryFileName';
    final prebuiltLibUri = input.packageRoot.resolve(prebuiltPath);
    
    await Directory.fromUri(input.outputDirectory).create(recursive: true);
    await File.fromUri(prebuiltLibUri).copy(libUri.toFilePath());
    
    output.addDependencies([prebuiltLibUri]);
    
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: '${input.packageName}_bindings_generated.dart',
        file: libUri,
        linkMode: linkMode,
        os: input.config.code.targetOS,
        architecture: input.config.code.targetArchitecture,
      ),
    );
  });
}