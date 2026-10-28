class BankBranch {
  const BankBranch({
    required this.id,
    required this.name,
    required this.governorate,
    required this.address,
    required this.mapsUri,
  });
  final String id, name, governorate, address;
  final Uri mapsUri;
}
